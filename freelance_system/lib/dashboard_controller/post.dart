import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import 'package:intl/intl.dart';
import 'package:freelance_system/dashboard_controller/jobpost.dart'; // Assuming JobPost is the widget for your job post box.

class Post extends StatefulWidget {
  final String userId;

  const Post({Key? key, required this.userId}) : super(key: key);

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('postId')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print('Error fetching posts: ${snapshot.error}');
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No posts yet.'));
              } else {
                var posts = snapshot.data!.docs;
                var unlikedPosts = [];
                var likedPosts = [];

                // Separate the posts into liked and unliked
                for (var post in posts) {
                  // Access the data from the snapshot and check if 'likes' field exists
                  var postData = post.data() as Map<String, dynamic>;
                  List likes = postData['likes'] ?? [];

                  if (likes.contains(widget.userId)) {
                    likedPosts.add(post);
                  } else {
                    unlikedPosts.add(post);
                  }
                }

                // Create a combined list with unliked posts first, then liked posts
                var allPosts = [...unlikedPosts, ...likedPosts];

                // Insert the JobPost box at the middle
                var middleIndex = (allPosts.length / 2).ceil();
                allPosts.insert(middleIndex,
                    'job_poster'); // Insert job post box in the middle

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: allPosts.length,
                  itemBuilder: (context, index) {
                    var post = allPosts[index];

                    // Check if it's the job post container (advertisement)
                    if (post == 'job_poster') {
                      return JobPost(); // Display the JobPost box
                    }

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

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        elevation: 5,
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
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        child: Text(
                                          username[0],
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        username,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                'Posted on: ${DateFormat('yyyy-MM-dd').format((post['timestamp'] as Timestamp).toDate())}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        const Color.fromARGB(255, 49, 49, 49)),
                              ),
                              SizedBox(height: 10),
                              if (status.isNotEmpty)
                                Text(
                                  status,
                                  style: TextStyle(fontSize: 16),
                                ),
                              SizedBox(height: 10),
                              if (imageUrl.isNotEmpty)
                                Imageslider(imageUrls: imageUrl),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${likes.length} likes',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.handshake,
                                      color: isLiked
                                          ? const Color.fromARGB(
                                              255, 101, 45, 255)
                                          : const Color.fromARGB(
                                              255, 86, 86, 86),
                                      size: 38,
                                    ),
                                    onPressed: () async {
                                      if (isLiked) {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(post.id)
                                            .update({
                                          'likes': FieldValue.arrayRemove(
                                              [widget.userId])
                                        });
                                      } else {
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(post.id)
                                            .update({
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
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
