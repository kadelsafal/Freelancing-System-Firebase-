// chat_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/chatroom_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTab extends StatelessWidget {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection("chatrooms")
          .where(Filter.or(
            Filter("sender_id", isEqualTo: user!.uid),
            Filter("receiver_id", isEqualTo: user!.uid),
          ))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No chatrooms available"));
        }

        final chatrooms = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatrooms.length,
          itemBuilder: (BuildContext context, int index) {
            String chatroomId = chatrooms[index].id;
            Map<String, dynamic>? data =
                chatrooms[index].data() as Map<String, dynamic>?;

            String senderId = data?['sender_id'] ?? '';
            String receiverId = data?['receiver_id'] ?? '';
            String senderName = data?['sender_name'] ?? '';
            String receiverName = data?['receiver_name'] ?? '';
            String lastmessage = data?['last_message'] ?? '';
            Timestamp? lastmessageTimestamp =
                data?['last_message_timestamp'] as Timestamp?;

            String chatroomTitle = '';
            if (user != null) {
              chatroomTitle = user!.uid == senderId ? receiverName : senderName;
            }

            String formattedTimestamp = lastmessageTimestamp != null
                ? DateFormat('HH:mm').format(lastmessageTimestamp.toDate())
                : 'No timestamp';

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
                  const SnackBar(
                      content: Text('Chatroom deleted successfully')),
                );
              },
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatroomScreen(
                        chatroomName: chatroomTitle,
                        chatroomId: chatroomId,
                        receiverId: receiverId,
                        receiverName: receiverName,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  child: Text(
                    chatroomTitle.isNotEmpty ? chatroomTitle[0] : "",
                  ),
                ),
                title: Text(chatroomTitle),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lastmessage),
                    Text(formattedTimestamp),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
