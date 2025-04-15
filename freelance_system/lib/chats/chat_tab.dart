import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/chatroom_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTab extends StatelessWidget {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  ChatTab({super.key});

  Future<bool> _isLastMessageUnseen(String chatroomId) async {
    final messagesSnapshot = await db
        .collection('chatrooms')
        .doc(chatroomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      final message = messagesSnapshot.docs.first.data();
      final seenBy = List<String>.from(message['isSeenBy'] ?? []);
      final senderId = message['senderId'];
      return !seenBy.contains(user!.uid) && senderId != user!.uid;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection("chatrooms")
          .where("participants", arrayContains: user!.uid)
          .orderBy("timestamp", descending: true)
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
            final chatroom = chatrooms[index];
            final chatroomId = chatroom.id;
            final data = chatroom.data() as Map<String, dynamic>;

            final participants = List<String>.from(data['participants'] ?? []);
            final lastMessage = data['last_message'] ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final participant1Name = data['participant1'] ?? '';
            final participant2Name = data['participant2'] ?? '';

            final isParticipant1 =
                participants.isNotEmpty && participants[0] == user!.uid;
            final chatroomTitle =
                isParticipant1 ? participant2Name : participant1Name;

            final formattedTimestamp = timestamp != null
                ? DateFormat('HH:mm').format(timestamp.toDate())
                : 'No timestamp';

            return FutureBuilder<bool>(
              future: _isLastMessageUnseen(chatroomId),
              builder: (context, seenSnapshot) {
                final isUnseen = seenSnapshot.data ?? false;

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
                    try {
                      final messagesSnapshot = await db
                          .collection("messages")
                          .where("chatroomsId", isEqualTo: chatroomId)
                          .get();

                      for (var doc in messagesSnapshot.docs) {
                        await doc.reference.delete();
                      }

                      await db.collection("chatrooms").doc(chatroomId).delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chatroom deleted successfully')),
                      );
                    } catch (e) {
                      print("Error deleting chatroom: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to delete chatroom')),
                      );
                    }
                  },
                  child: ListTile(
                    onTap: () {
                      final otherUserId =
                          participants.firstWhere((id) => id != user!.uid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatroomScreen(
                            chatroomName: chatroomTitle,
                            chatroomId: chatroomId,
                            userId: otherUserId,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      child: Text(
                        chatroomTitle.isNotEmpty ? chatroomTitle[0] : "",
                        style: TextStyle(
                          fontWeight:
                              isUnseen ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    title: Text(chatroomTitle),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnseen
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTimestamp,
                          style: TextStyle(
                            fontWeight:
                                isUnseen ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
