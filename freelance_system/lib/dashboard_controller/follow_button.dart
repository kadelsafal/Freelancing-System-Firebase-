import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String viewedUserId;

  FollowButton({required this.currentUserId, required this.viewedUserId});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    checkFollowStatus();
  }

  Future<void> checkFollowStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('following')
        .doc(widget.viewedUserId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> followUser() async {
    final db = FirebaseFirestore.instance;

    await db
        .collection('users')
        .doc(widget.currentUserId)
        .collection('following')
        .doc(widget.viewedUserId)
        .set({"timestamp": FieldValue.serverTimestamp()});

    await db
        .collection('users')
        .doc(widget.viewedUserId)
        .collection('followers')
        .doc(widget.currentUserId)
        .set({"timestamp": FieldValue.serverTimestamp()});

    await db.collection('users').doc(widget.currentUserId).update({
      "followed": FieldValue.increment(1),
    });

    await db.collection('users').doc(widget.viewedUserId).update({
      "followers": FieldValue.increment(1),
    });

    setState(() {
      isFollowing = true;
    });
  }

  Future<void> unfollowUser() async {
    final db = FirebaseFirestore.instance;

    await db
        .collection('users')
        .doc(widget.currentUserId)
        .collection('following')
        .doc(widget.viewedUserId)
        .delete();

    await db
        .collection('users')
        .doc(widget.viewedUserId)
        .collection('followers')
        .doc(widget.currentUserId)
        .delete();

    await db.collection('users').doc(widget.currentUserId).update({
      "followed": FieldValue.increment(-1),
    });

    await db.collection('users').doc(widget.viewedUserId).update({
      "followers": FieldValue.increment(-1),
    });

    setState(() {
      isFollowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isFollowing ? unfollowUser : followUser,
      child: Text(isFollowing ? 'Following' : 'Follow'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.green : Colors.blue,
      ),
    );
  }
}
