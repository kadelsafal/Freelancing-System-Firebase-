import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/chat_service.dart';
import 'package:freelance_system/profile_controller/mypost.dart';
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

  int followers = 0;
  int followed = 0;
  bool isFollowing = false;
  bool isFollowedByThem = false; // NEW
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
    final db = FirebaseFirestore.instance;

    final followingDoc = await db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(widget.userId)
        .get();

    final followedByThemDoc = await db
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .doc(currentUserId)
        .get();

    setState(() {
      isFollowing = followingDoc.exists;
      isFollowedByThem = followedByThemDoc.exists;
    });
  }

  Future<void> fetchLastMessage() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final message = await ChatService.getLastMessage(
        currentUserId: currentUserId,
        otherUserId: widget.userId,
      );

      if (message != null) {
        setState(() {
          lastMessage = message;
        });
      }
    } catch (e) {
      print("Error fetching last message: $e");
    }
  }

  Future<void> followUser(String targetUserId, String targetUserName) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    final currentUserDoc =
        await db.collection('users').doc(currentUserId).get();
    final currentUserName = currentUserDoc['Full Name'] ?? '';

    // Add to following
    await db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'fullName': targetUserName,
    });

    // Add to followers
    await db
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId)
        .set({
      'timestamp': FieldValue.serverTimestamp(),
      'fullName': currentUserName,
    });

    // Update counts
    await db.collection('users').doc(currentUserId).update({
      'followed': FieldValue.increment(1),
    });
    await db.collection('users').doc(targetUserId).update({
      'followers': FieldValue.increment(1),
    });

    // 🔔 Add notification
    await db
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add({
      'type': 'follow',
      'fromUserId': currentUserId,
      'fromUserName': currentUserName,
      'message': '$currentUserName followed you',
      'seen': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> handleFollow() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (isFollowing) {
      // Unfollow logic
      final db = FirebaseFirestore.instance;
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
      // Follow logic using the followUser function
      await followUser(widget.userId, widget.userName);
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
                  // Follow & Message Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isFollowing && isFollowedByThem)
                        ElevatedButton(
                          onPressed: handleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Follow Back"),
                        ),
                      if (!isFollowing && !isFollowedByThem)
                        ElevatedButton(
                          onPressed: handleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Follow"),
                        ),
                      if (isFollowing)
                        ElevatedButton(
                          onPressed: handleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text("Following"),
                        ),
                      if (isFollowing || isFollowedByThem)
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final currentUserId =
                                  FirebaseAuth.instance.currentUser!.uid;
                              final currentUserName = Provider.of<Userprovider>(
                                      context,
                                      listen: false)
                                  .userName;

                              final chatroomId =
                                  await ChatService.createOrUpdateChatroom(
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                otherUserId: widget.userId,
                                otherUserName: widget.userName,
                                lastMessage: lastMessage,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatroomScreen(
                                    chatroomId: chatroomId,
                                    chatroomName: widget.userName,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
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
                  ),
                  SizedBox(height: 20),

// Show Posts if both follow each other
                  if (isFollowing && isFollowedByThem)
                    MyPost(
                      userId: widget.userId,
                      isOwnProfile: FirebaseAuth.instance.currentUser!.uid ==
                          widget.userId,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Follow each other to view posts. Start connecting now!",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
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
