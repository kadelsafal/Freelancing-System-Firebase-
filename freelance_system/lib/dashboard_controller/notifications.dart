import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> handleFollowBack(String userId, String userName) async {
    final db = FirebaseFirestore.instance;

    await db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(userId)
        .set({"timestamp": FieldValue.serverTimestamp()});
    await db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .doc(currentUserId)
        .set({"timestamp": FieldValue.serverTimestamp()});
    await db
        .collection('users')
        .doc(currentUserId)
        .update({"followed": FieldValue.increment(1)});
    await db
        .collection('users')
        .doc(userId)
        .update({"followers": FieldValue.increment(1)});

    // Remove only the specific notification
    final notificationsRef =
        db.collection('users').doc(currentUserId).collection('notifications');
    final querySnapshot =
        await notificationsRef.where("fromUserId", isEqualTo: userId).get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      print("No notifications found to delete for user: $userId");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text("${data['fromUserName']} started following you."),
                subtitle: Text("Tap to follow back."),
                trailing: ElevatedButton(
                  onPressed: () => handleFollowBack(
                      data['fromUserId'], data['fromUserName']),
                  child: Text("Follow Back"),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
