import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import 'package:intl/intl.dart';

class MyPost extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const MyPost({super.key, required this.userId, required this.isOwnProfile});

  @override
  _MyPostState createState() => _MyPostState();
}

class _MyPostState extends State<MyPost> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            " Posts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: widget.userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              } else {
                var posts = snapshot.data!.docs;

                // 🔁 Use Column to build each post instead of ListView
                return Column(
                  children: posts.map((post) {
                    List<String> imageUrl = [];
                    var imageUrlsData = post['imageUrls'];

                    if (imageUrlsData != null) {
                      if (imageUrlsData is String) {
                        imageUrl = [imageUrlsData];
                      } else if (imageUrlsData is List) {
                        imageUrl = List<String>.from(imageUrlsData);
                      }
                    }

                    String username = post['username'];
                    String status = post['status'] ?? '';
                    List likes = post['likes'] ?? [];
                    bool isLiked = likes.contains(widget.userId);
                    String postUserId = post['userId'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(postUserId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      String initial = username.isNotEmpty
                                          ? username[0]
                                          : '?';

                                      final userData = snapshot.data?.data()
                                          as Map<String, dynamic>?;

                                      final profileImage =
                                          (userData?['profile_image'] ?? '')
                                                  .isEmpty
                                              ? null
                                              : userData?['profile_image'];

                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                Colors.blue.shade900,
                                            backgroundImage:
                                                profileImage != null
                                                    ? NetworkImage(profileImage)
                                                    : null,
                                            child: profileImage == null
                                                ? Text(initial,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20))
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(username,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.blue)),
                                        ],
                                      );
                                    },
                                  ),
                                  if (widget.isOwnProfile)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(post.id)
                                            .delete();
                                      },
                                    ),
                                ],
                              ),
                              Text(
                                'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((post['timestamp'] as Timestamp).toDate())}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 49, 49, 49),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (status.isNotEmpty)
                                Text(status,
                                    style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              if (imageUrl.isNotEmpty)
                                Imageslider(imageUrls: imageUrl),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${likes.length} likes',
                                      style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: Icon(
                                      Icons.handshake,
                                      color: isLiked
                                          ? const Color.fromARGB(
                                              255, 6, 119, 225)
                                          : Colors.grey,
                                      size: 38,
                                    ),
                                    onPressed: () async {
                                      final postRef = FirebaseFirestore.instance
                                          .collection('posts')
                                          .doc(post.id);
                                      if (isLiked) {
                                        await postRef.update({
                                          'likes': FieldValue.arrayRemove(
                                              [widget.userId])
                                        });
                                      } else {
                                        await postRef.update({
                                          'likes': FieldValue.arrayUnion(
                                              [widget.userId])
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
