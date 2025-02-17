import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to send a notification
  Future<void> sendNotification(String receiverId, String message) async {
    try {
      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'message': message,
        'read': false, // Initially unread
        'timestamp': FieldValue.serverTimestamp(), // For sorting
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
