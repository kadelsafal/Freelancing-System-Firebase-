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

  // Send message function
  Future<void> sendMessage() async {
    if (messageText.text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final currentUserName =
        Provider.of<Userprovider>(context, listen: false).userName;

    final receiverId = widget.receiverId;
    // Store message before clearing the text field
    final String messageContent = messageText.text.trim();
    messageText.clear();
    // Create the message data to send to Firestore
    Map<String, dynamic> messageToSend = {
      "text": messageContent,
      "sender_name": currentUserName,
      "sender_id": currentUserId,
      "receiver_name": widget.receiverName,
      "receiver_id": receiverId,
      "chatroomsId": widget.chatroomId,
      "timestamp": FieldValue.serverTimestamp(),
    };

    try {
      // Add the message to the messages collection
      await db.collection("messages").add(messageToSend);

      // Update the chatroom with the latest message
      await db.collection("chatrooms").doc(widget.chatroomId).update({
        "last_message": messageContent,
        "last_message_timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Function to format timestamp
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Example format: 14:05
  }

  // Function to delete message (unsend)
  Future<void> unsendMessage(String messageId) async {
    try {
      await db.collection("messages").doc(messageId).delete();
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  // Display individual message
  Widget singleChatItem({
    required String sender_name,
    required String text,
    required String sender_id,
    required Timestamp timestamp,
    required String messageId, // Message ID to delete
    required BuildContext context,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return GestureDetector(
      onLongPress: () {
        if (sender_id == currentUserId) {
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
        crossAxisAlignment: sender_id == currentUserId
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (sender_id != currentUserId)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                sender_name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: sender_id == currentUserId
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: sender_id == currentUserId
                        ? Colors.deepPurple
                        : Colors.purple[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: sender_id == currentUserId
                          ? Radius.circular(20)
                          : Radius.circular(0),
                      bottomRight: sender_id == currentUserId
                          ? Radius.circular(0)
                          : Radius.circular(20),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: sender_id == currentUserId
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatroomName,
          style: TextStyle(color: Colors.white), // White text color
        ),
        backgroundColor: Colors.deepPurple, // Deep purple background
        iconTheme: IconThemeData(color: Colors.white), // White back button/icon
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
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading messages"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                final allMessages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    final previousMessage = index < allMessages.length - 1
                        ? allMessages[index + 1]
                        : null;

                    Timestamp timestamp =
                        message["timestamp"] ?? Timestamp.now();
                    Timestamp? prevTimestamp = previousMessage?["timestamp"];

                    bool shouldShowTimestamp = false;

                    if (prevTimestamp != null) {
                      DateTime currentTime = timestamp.toDate();
                      DateTime prevTime = prevTimestamp.toDate();

                      // Show timestamp if there is a 5-minute gap
                      if (currentTime.difference(prevTime).inMinutes > 5) {
                        shouldShowTimestamp = true;
                      }
                    } else {
                      shouldShowTimestamp =
                          true; // Show timestamp for the first message
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
                                  fontSize: 14,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          child: singleChatItem(
                            sender_name: message["sender_name"],
                            text: message["text"],
                            sender_id: message["sender_id"],
                            timestamp: timestamp,
                            messageId: message.id,
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
                            borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 3), // Thick border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 3), // Thick border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 3.5), // Even thicker when focused
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
                      child: Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
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
