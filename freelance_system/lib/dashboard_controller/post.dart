import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/dashboard_controller/postcard.dart';
import 'package:intl/intl.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import 'package:freelance_system/dashboard_controller/jobpost.dart';

class Post extends StatelessWidget {
  final String userId;

  const Post({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          var allPosts = snapshot.data!.docs;

          var middleIndex = (allPosts.length / 2).ceil();
          List<dynamic> displayPosts = List.from(allPosts);
          displayPosts.insert(middleIndex, 'job_poster');

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              var item = displayPosts[index];

              if (item == 'job_poster') return const JobPost();

              return PostCard(post: item, userId: userId);
            },
          );
        },
      ),
    );
  }
}
