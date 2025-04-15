import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  /// Updates or creates a chatroom document
  static Future<String> createOrUpdateChatroom({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    required String lastMessage,
  }) async {
    try {
      final chatroomId = currentUserId.compareTo(otherUserId) < 0
          ? "$currentUserId-$otherUserId"
          : "$otherUserId-$currentUserId";

      final chatroomRef =
          FirebaseFirestore.instance.collection('chatrooms').doc(chatroomId);

      await chatroomRef.set({
        "chatroom_id": chatroomId,
        "participants": [currentUserId, otherUserId],
        "participant1": currentUserName,
        "participant2": otherUserName,
        "last_message": lastMessage,
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return chatroomId;
    } catch (e) {
      print("Error creating/updating chatroom: $e");
      rethrow;
    }
  }

  static Future<String?> getLastMessage({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final chatroomId = currentUserId.compareTo(otherUserId) < 0
          ? "$currentUserId-$otherUserId"
          : "$otherUserId-$currentUserId";

      final messagesCollection = FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(chatroomId)
          .collection('messages');

      final lastMessageSnapshot = await messagesCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMessageSnapshot.docs.isNotEmpty) {
        return lastMessageSnapshot.docs.first.data()['text'] ?? '';
      }
    } catch (e) {
      print("Error fetching last message: $e");
    }
    return null;
  }

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
