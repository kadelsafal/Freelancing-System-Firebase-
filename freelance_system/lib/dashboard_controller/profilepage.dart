import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import '../chats/chatroom_screen.dart';

class Profilepage extends StatefulWidget {
  final String userId;
  final String userName;

  const Profilepage({super.key, required this.userId, required this.userName});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  late Future<Map<String, dynamic>> userData;
  bool isFollowing = false;
  int followers = 0;
  int followed = 0;
  String lastMessage = '';

  @override
  void initState() {
    super.initState();
    fetchInitialData();
    fetchLastMessage();
  }

  Future<void> fetchInitialData() async {
    userData = fetchUserData();
    await fetchFollowerCount();
    checkFollowStatus();
    await fetchLastMessage();
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }

  Future<void> fetchFollowerCount() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          followers = userSnapshot['followers'] ?? 0;
          followed = userSnapshot['followed'] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching follower count: $e");
    }
  }

  Future<void> checkFollowStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final followingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(widget.userId)
        .get();

    setState(() {
      isFollowing = followingDoc.exists;
    });
  }

  Future<void> fetchLastMessage() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final chatroomId = currentUserId.compareTo(widget.userId) < 0
          ? "$currentUserId-${widget.userId}"
          : "${widget.userId}-$currentUserId";

      final messagesCollection = FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(chatroomId)
          .collection('messages');
      final lastMessageSnapshot = await messagesCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMessageSnapshot.docs.isNotEmpty) {
        setState(() {
          lastMessage = lastMessageSnapshot.docs.first['text'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching last message: $e");
    }
  }

  Future<void> sendFollowNotification(
      String currentUserId, String currentUserName) async {
    try {
      final db = FirebaseFirestore.instance;
      await db
          .collection('users')
          .doc(widget.userId)
          .collection('notifications')
          .add({
        "type": "follow",
        "fromUserId": currentUserId,
        "fromUserName": currentUserName,
        "timestamp": FieldValue.serverTimestamp(),
        "seen": false, // Mark as unread
      });
    } catch (e) {
      print("Error sending follow notification: $e");
    }
  }

  Future<void> handleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final currentUserName =
        Provider.of<Userprovider>(context, listen: false).userName;
    final db = FirebaseFirestore.instance;

    if (isFollowing) {
      // Unfollow logic
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.userId)
          .delete();
      await db
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUserId)
          .delete();
      await db
          .collection('users')
          .doc(currentUserId)
          .update({"followed": FieldValue.increment(-1)});
      await db
          .collection('users')
          .doc(widget.userId)
          .update({"followers": FieldValue.increment(-1)});

      setState(() {
        isFollowing = false;
        followers--;
      });
    } else {
      // Follow logic
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(widget.userId)
          .set({
        "timestamp": FieldValue.serverTimestamp(),
        "fullName": widget.userName,
      });
      await db
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        "timestamp": FieldValue.serverTimestamp(),
        "fullName": currentUserName,
      });
      await db
          .collection('users')
          .doc(currentUserId)
          .update({"followed": FieldValue.increment(1)});
      await db
          .collection('users')
          .doc(widget.userId)
          .update({"followers": FieldValue.increment(1)});

      setState(() {
        isFollowing = true;
        followers++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(child: Text("Error loading profile data."));
          } else {
            final data = snapshot.data!;
            final rating = data['rating'] ?? 0.0;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Avatar and Name
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Followers, Followed, and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            followers.toString(),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Followers",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            followed.toString(),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Followed",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Rating",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Follow and Message Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isFollowing)
                        ElevatedButton(
                          onPressed: handleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Follow"),
                        ),
                      if (isFollowing) ...[
                        ElevatedButton(
                          onPressed: handleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Following"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final currentUserId =
                                  FirebaseAuth.instance.currentUser!.uid;
                              final currentUserName = Provider.of<Userprovider>(
                                context,
                                listen: false,
                              ).userName;

                              final chatroomId =
                                  currentUserId.compareTo(widget.userId) < 0
                                      ? "$currentUserId-${widget.userId}"
                                      : "${widget.userId}-$currentUserId";

                              // Get the reference to the chatroom
                              final chatroomRef = FirebaseFirestore.instance
                                  .collection('chatrooms')
                                  .doc(chatroomId);

                              // Add or update the chatroom with the latest message
                              await chatroomRef.set({
                                "chatroom_id": chatroomId,
                                "participants": [currentUserId, widget.userId],
                                "participant1": currentUserName,
                                "participant2": widget.userName,
                                "last_message": lastMessage,
                                "timestamp": FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));

                              // Navigate to the ChatroomScreen
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatroomScreen(
                                      chatroomId: chatroomId,
                                      chatroomName: widget.userName,
                                      userId: widget.userId,
                                    ),
                                  ));
                            } catch (e) {
                              print("Error opening chatroom: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Failed to open chatroom. Please try again.")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Message"),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
