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

  ChatroomScreen({
    super.key,
    required this.chatroomId,
    required this.chatroomName,
    required this.receiverId,
    required this.receiverName,
    required String lastmessage,
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
    messageText.clear();
  }

  // Display individual message
  Widget singleChatItem({
    required String sender_name,
    required String text,
    required String sender_id,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      crossAxisAlignment: sender_id == currentUserId
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (sender_id != currentUserId) // Show name only for received messages
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              sender_name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: sender_id == currentUserId ? Colors.blue : Colors.grey[300],
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              color: sender_id == currentUserId ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatroomName)),
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      child: singleChatItem(
                        sender_name: message["sender_name"],
                        text: message["text"],
                        sender_id: message["sender_id"],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[300],
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageText,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: sendMessage,
                    child: Icon(Icons.send, color: Colors.blue),
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
