import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/providers/userProvider.dart';

class ChatroomScreen extends StatefulWidget {
  final String chatroomName;
  final String chatroomId;
  final String receiverId;
  final String receiverName;

  const ChatroomScreen({
    super.key,
    required this.chatroomId,
    required this.chatroomName,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends State<ChatroomScreen> {
  TextEditingController messageText = TextEditingController();
  final db = FirebaseFirestore.instance;
  late String currentUserId;
  late String currentUserName;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    Future.delayed(Duration.zero, () {
      currentUserName =
          Provider.of<Userprovider>(context, listen: false).userName;
      markMessagesAsRead();
      setState(() {
        isInitialized = true;
      });
    });
  }

  Future<void> markMessagesAsRead() async {
    try {
      QuerySnapshot unreadMessages = await db
          .collection("messages")
          .where("chatroomsId", isEqualTo: widget.chatroomId)
          .where("receiver_id", isEqualTo: currentUserId)
          .where("is_read", isEqualTo: false)
          .get();

      WriteBatch batch = db.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference,
            {"is_read": true, "read_at": FieldValue.serverTimestamp()});
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  Future<void> sendMessage() async {
    if (messageText.text.isEmpty) return;

    final String messageContent = messageText.text.trim();
    messageText.clear();

    // Dynamically determine the receiver
    // Chatroom name assumed to be "User A & User B"
    List<String> participants = widget.chatroomName.split(" & ");
    String receiverName =
        participants.firstWhere((name) => name != currentUserName);

    // You should resolve receiver ID from name; assuming a Firestore 'users' collection
    String receiverId = "";
    try {
      QuerySnapshot query = await db
          .collection("users")
          .where("Full Name", isEqualTo: receiverName)
          .limit(1)
          .get();
      // Check if the query returns any results
      if (query.docs.isNotEmpty) {
        // Resolve receiverId from the query result
        receiverId = query.docs.first.id;
        print("✅ Found receiverId: $receiverId");
      } else {
        print("⚠️ No user found with username: $receiverName");
        // You can add fallback here or handle the error appropriately (e.g., show an alert)
        return; // Do not send the message if the receiver ID is empty
      }
    } catch (e) {
      print("Error fetching receiver ID: $e");
      return;
    }

    Map<String, dynamic> messageToSend = {
      "text": messageContent,
      "sender_name": currentUserName,
      "sender_id": currentUserId,
      "receiver_name": receiverName,
      "receiver_id": receiverId,
      "chatroomsId": widget.chatroomId,
      "timestamp": FieldValue.serverTimestamp(),
      "is_read": false,
      "read_at": null,
    };

    try {
      await db.collection("messages").add(messageToSend);
      await db.collection("chatrooms").doc(widget.chatroomId).update({
        "last_message": messageContent,
        "last_message_timestamp": FieldValue.serverTimestamp(),
        "last_message_sender_id": currentUserId,
        "last_message_is_read": false,
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> unsendMessage(String messageId) async {
    try {
      await db.collection("messages").doc(messageId).delete();
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  Widget getUserAvatar(String userId, double size) {
    if (userId.isEmpty) {
      return CircleAvatar(
        radius: size,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: size * 1.2, color: Colors.grey[700]),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: db.collection("users").doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String? profileImageUrl = userData['profileImageUrl'];

          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            return CircleAvatar(
              radius: size,
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }
        return CircleAvatar(
          radius: size,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: size * 1.2, color: Colors.grey[700]),
        );
      },
    );
  }

  Widget singleChatItem({
    required String sender_name,
    required String text,
    required String sender_id,
    required String receiver_id,
    required Timestamp timestamp,
    required String messageId,
    required bool isRead,
    Timestamp? readAt,
    required BuildContext context,
  }) {
    final isSentByMe = sender_id == currentUserId;

    return GestureDetector(
      onLongPress: () {
        if (isSentByMe) {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text("Unsend Message"),
                content: Text("Do you want to delete this message?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      unsendMessage(messageId);
                      Navigator.pop(dialogContext);
                    },
                    child: Text("Unsend", style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Column(
        crossAxisAlignment:
            isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isSentByMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                sender_name == currentUserName ? "You" : sender_name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
                isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSentByMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: getUserAvatar(sender_id, 16),
                ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.deepPurple : Colors.purple[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft:
                          isSentByMe ? Radius.circular(20) : Radius.circular(0),
                      bottomRight:
                          isSentByMe ? Radius.circular(0) : Radius.circular(20),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSentByMe ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              if (isSentByMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: isRead
                      ? getUserAvatar(receiver_id, 12)
                      : Icon(Icons.check, size: 16, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text(widget.chatroomName, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          iconTheme: IconThemeData(color: Colors.white),
          toolbarHeight: 80.0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            getUserAvatar(widget.receiverId, 20),
            SizedBox(width: 12),
            Text(widget.chatroomName, style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        toolbarHeight: 80.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection("messages")
                  .where("chatroomsId", isEqualTo: widget.chatroomId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepPurple));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading messages"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  markMessagesAsRead();
                }

                final allMessages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = allMessages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final previousMessage = index < allMessages.length - 1
                        ? allMessages[index + 1].data() as Map<String, dynamic>
                        : null;

                    final String senderId = message["sender_id"] ?? "";
                    final String senderName =
                        message["sender_name"] ?? "Unknown";
                    final String receiverId = message["receiver_id"] ?? "";
                    final String messageText = message["text"] ?? "";
                    final bool isRead = message["is_read"] ?? false;
                    Timestamp timestamp =
                        message["timestamp"] ?? Timestamp.now();
                    Timestamp? prevTimestamp = previousMessage?["timestamp"];
                    Timestamp? readAt = message["read_at"];

                    bool shouldShowTimestamp = false;
                    if (prevTimestamp != null) {
                      DateTime currentTime = timestamp.toDate();
                      DateTime prevTime = prevTimestamp.toDate();
                      if (currentTime.difference(prevTime).inMinutes > 5) {
                        shouldShowTimestamp = true;
                      }
                    } else {
                      shouldShowTimestamp = true;
                    }

                    return Column(
                      children: [
                        if (shouldShowTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Text(
                                formatTimestamp(timestamp),
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          child: singleChatItem(
                            sender_name: senderName,
                            text: messageText,
                            sender_id: senderId,
                            receiver_id: receiverId,
                            timestamp: timestamp,
                            messageId: messageDoc.id,
                            isRead: isRead,
                            readAt: readAt,
                            context: context,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: messageText,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                                BorderSide(color: Colors.deepPurple, width: 3),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                                BorderSide(color: Colors.deepPurple, width: 3),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Colors.deepPurple, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send_outlined,
                          color: Colors.white, size: 30),
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
}
