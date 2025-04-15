import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static Stream<int> getUnseenChatsCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection('chatrooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnseen = 0;

      for (var chatDoc in snapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .get();

        for (var messageDoc in messagesSnapshot.docs) {
          final data = messageDoc.data();
          final isSeenBy = List<String>.from(data['isSeenBy'] ?? []);
          final senderId = data['senderId'];

          if (!isSeenBy.contains(userId) && senderId != userId) {
            totalUnseen++;
            break; // Count only 1 unseen message per chatroom
          }
        }
      }

      return totalUnseen;
    });
  }
}
