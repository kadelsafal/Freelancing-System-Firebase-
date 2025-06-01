import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/user_service.dart';

class ChatroomScreen extends StatefulWidget {
  final String chatroomId;
  final String chatroomName;
  final String userId;

  const ChatroomScreen({
    super.key,
    required this.chatroomId,
    required this.chatroomName,
    required this.userId,
  });

  @override
  State<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends State<ChatroomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chatrooms')
        .doc(widget.chatroomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'recieverId': widget.userId,
      'text': text,
      'timestamp': timestamp,
      'isSeenBy': [],
    });

    // Update the last message and timestamp in the parent chatroom doc
    await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
      'last_message': text,
      'timestamp': timestamp, // Force sync for ordering in chat list
    });

    _messageController.clear();
  }

  void _markMessagesAsSeen(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final seenList = List<String>.from(data['isSeenBy'] ?? []);

      if (!seenList.contains(currentUser!.uid) &&
          data['senderId'] != currentUser!.uid) {
        await doc.reference.update({
          'isSeenBy': FieldValue.arrayUnion([currentUser!.uid])
        });
      }
    }
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;
        _markMessagesAsSeen(snapshot.data!);

        // Find the index of the *latest* message that was seen by the other user
        int? lastSeenIndex;
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i].data() as Map<String, dynamic>;
          final isSeenBy = List<String>.from(msg['isSeenBy'] ?? []);
          final senderId = msg['senderId'];

          // Current user is sender, and the other user has seen it
          if (senderId == currentUser!.uid &&
              isSeenBy.contains(widget.userId)) {
            lastSeenIndex ??= i; // First one (most recent due to reverse order)
            break;
          }
        }

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final senderId = message['senderId'];
            final text = message['text'] ?? '';
            final timestamp = message['timestamp'] as Timestamp?;
            final isMe = senderId == currentUser!.uid;

            final showSeenAvatar = isMe && index == lastSeenIndex;

            return FutureBuilder<Map<String, dynamic>>(
              future: UserService.getUserProfile(widget.userId),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data ?? {};
                final userName = userData['name'] ?? '';
                final profileImage = userData['profileImage'];
                final seenByInitial =
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?';

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4.0, left: 4.0),
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color.fromARGB(221, 0, 0, 0),
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF1976D2),
                                  backgroundImage: (profileImage != null &&
                                          profileImage.isNotEmpty)
                                      ? NetworkImage(profileImage)
                                      : null,
                                  child: (profileImage == null ||
                                          profileImage.isEmpty)
                                      ? Text(
                                          seenByInitial,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (timestamp != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _formatTimestamp(timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  subtitle: showSeenAvatar
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF1976D2),
                                backgroundImage: (profileImage != null &&
                                        profileImage.isNotEmpty)
                                    ? NetworkImage(profileImage)
                                    : null,
                                child: (profileImage == null ||
                                        profileImage.isEmpty)
                                    ? Text(seenByInitial,
                                        style: const TextStyle(
                                            color: Colors.white))
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Seen",
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: FutureBuilder<Map<String, dynamic>>(
          future: UserService.getUserProfile(widget.userId),
          builder: (context, userSnapshot) {
            String profileImage = '';
            String seenByInitial = widget.chatroomName.isNotEmpty
                ? widget.chatroomName[0].toUpperCase()
                : '?';

            if (userSnapshot.hasData) {
              final userData = userSnapshot.data!;
              profileImage = userData['profileImage'] ?? '';
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1976D2),
                  backgroundImage: (profileImage.isNotEmpty)
                      ? NetworkImage(profileImage)
                      : null,
                  child: (profileImage == null || profileImage.isEmpty)
                      ? Text(seenByInitial,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.chatroomName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0xFF1976D2), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0xFF1976D2), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
