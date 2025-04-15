import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  late Stream<QuerySnapshot> notificationsStream;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> handleFollowBack(String fromUserId, String fromUserName) async {
    final db = FirebaseFirestore.instance;

    try {
      // Add to current user's following
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(fromUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'fullName': fromUserName,
      });

      // Add to from user's followers
      final currentUserDoc =
          await db.collection('users').doc(currentUserId).get();
      final currentUserName = currentUserDoc['Full Name'] ?? '';

      await db
          .collection('users')
          .doc(fromUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'fullName': currentUserName,
      });

      // Update follow counts
      await db.collection('users').doc(currentUserId).update({
        'followed': FieldValue.increment(1),
      });
      await db.collection('users').doc(fromUserId).update({
        'followers': FieldValue.increment(1),
      });

      // 🔔 Create a follow-back notification for the other user
      await db
          .collection('users')
          .doc(fromUserId)
          .collection('notifications')
          .add({
        'type': 'follow',
        'fromUserId': currentUserId,
        'fromUserName': currentUserName,
        'message': '$currentUserName followed you back',
        'seen': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You followed back $fromUserName')),
      );
    } catch (e) {
      print("Error in follow back: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow back')),
      );
    }
  }

  Future<bool> checkIfFollowing(String otherUserId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(otherUserId)
        .get();
    return doc.exists;
  }

  String formatTimestamp(Timestamp timestamp) {
    // Format the timestamp into a human-readable format
    return DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final type = notif['type'];
              final fromUserId = notif['fromUserId'];
              final fromUserName = notif['fromUserName'];
              final message = notif['message'];
              final seen = notif['seen'] ?? false;
              final timestamp = notif['timestamp'] as Timestamp;

              return FutureBuilder<bool>(
                future: checkIfFollowing(fromUserId),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(fromUserName.isNotEmpty
                          ? fromUserName[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(message ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type),
                        const SizedBox(height: 4),
                        Text(
                          formatTimestamp(timestamp),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: type == "follow"
                        ? isFollowing
                            ? const Text(
                                "Following",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 90, 57, 255),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              )
                            : ElevatedButton(
                                onPressed: () =>
                                    handleFollowBack(fromUserId, fromUserName),
                                child: const Text("Follow Back"),
                              )
                        : null,
                    tileColor:
                        !seen ? Colors.blue.withOpacity(0.05) : Colors.white,
                    onTap: () async {
                      // Mark notification as seen
                      await notif.reference.update({"seen": true});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
