import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import 'package:intl/intl.dart';

class MyPost extends StatefulWidget {
  final String userId;

  const MyPost({Key? key, required this.userId}) : super(key: key);

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
          Text(
            "My Posts",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: widget.userId)
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
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
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
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
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
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        const Color.fromARGB(255, 49, 49, 49)),
                              ),
                              SizedBox(height: 10),
                              // Displaying the status above the image slider
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
                                              255, 234, 169, 5)
                                          : Colors.grey,
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
