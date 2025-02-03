import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/chatroom_screen.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser; // Keep it nullable

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("chatrooms")
            .where("sender_id", isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No chatrooms available"));
          }

          final chatrooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatrooms.length,
            itemBuilder: (BuildContext context, int index) {
              String chatroomId = chatrooms[index].id;
              Map<String, dynamic>? data =
                  chatrooms[index].data() as Map<String, dynamic>?;

              // Fetch sender and receiver details from the chatroom document
              String senderId = data?['sender_id'] ?? '';
              String receiverId = data?['receiver_id'] ?? '';
              String senderName = data?['sender_name'] ?? '';
              String receiverName = data?['receiver_name'] ?? '';

              // Determine the chatroom title based on the current user
              String chatroomTitle = '';
              if (user != null) {
                // Check if the current user is the sender or receiver
                if (user!.uid == senderId) {
                  chatroomTitle =
                      receiverName; // Show the receiver's name if current user is the sender
                } else if (user!.uid == receiverId) {
                  chatroomTitle =
                      senderName; // Show the sender's name if current user is the receiver
                }
              }

              return Dismissible(
                key: Key(chatroomId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await db.collection("chatrooms").doc(chatroomId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chatroom deleted successfully')),
                  );
                },
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ChatroomScreen(
                            chatroomName: chatroomTitle,
                            chatroomId: chatroomId,
                            receiverId: receiverId,
                            receiverName: receiverName,
                          );
                        },
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    child: Text(
                      chatroomTitle.isNotEmpty ? chatroomTitle[0] : "",
                    ),
                  ),
                  title: Text(chatroomTitle),
                  subtitle: Text("Tap to enter the chatroom"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
