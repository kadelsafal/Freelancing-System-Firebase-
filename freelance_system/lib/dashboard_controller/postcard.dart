import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/screens/profile.dart';
import 'package:intl/intl.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import '../dashboard_controller/profilepage.dart';

class PostCard extends StatefulWidget {
  final QueryDocumentSnapshot post;
  final String userId;

  const PostCard({super.key, required this.post, required this.userId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> postData;
  late List likes;
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    postData = widget.post.data() as Map<String, dynamic>;
    likes = List.from(postData['likes'] ?? []);
    isLiked = likes.contains(widget.userId);
  }

  void _toggleLike() async {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(widget.userId);
      } else {
        likes.remove(widget.userId);
      }
    });

    try {
      await postRef.update({
        'likes': isLiked
            ? FieldValue.arrayUnion([widget.userId])
            : FieldValue.arrayRemove([widget.userId]),
      });
    } catch (e) {
      // Revert on failure
      setState(() {
        isLiked = !isLiked;
        if (isLiked) {
          likes.add(widget.userId);
        } else {
          likes.remove(widget.userId);
        }
      });
      print("Failed to update likes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = postData['username'] ?? 'User';
    String status = postData['status'] ?? '';
    final String postUserId = postData['userId'];
    List<String> imageUrl = [];

    var imageUrlsData = postData['imageUrls'];
    if (imageUrlsData is String) {
      imageUrl = [imageUrlsData];
    } else if (imageUrlsData is List) {
      imageUrl = List<String>.from(imageUrlsData);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1976D2), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(postUserId)
                    .get(),
                builder: (context, snapshot) {
                  String initial = username.isNotEmpty ? username[0] : '?';

                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  final profileImage =
                      (userData?['profile_image'] ?? '').isEmpty
                          ? null
                          : userData?['profile_image'];

                  return GestureDetector(
                    onTap: () {
                      // Check if the current user is the same as the post's user
                      if (widget.userId == postUserId) {
                        // Navigate to the profile screen for the current user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      } else {
                        // Navigate to the profile page of the post's user
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profilepage(
                              userId: postUserId,
                              userName: username,
                              userImage:
                                  profileImage ?? '', // Pass image or empty
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(12),
                            image: profileImage != null
                                ? DecorationImage(
                                    image: NetworkImage(profileImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: profileImage == null
                              ? Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                                fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              if (status.isNotEmpty || imageUrl.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE3F0FB),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.isNotEmpty)
                        Text(
                          status,
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF1976D2)),
                        ),
                      const SizedBox(height: 10),
                      if (imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Imageslider(imageUrls: imageUrl),
                        ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${likes.length} likes',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1976D2)),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.handshake : Icons.handshake_outlined,
                      color: isLiked ? Color(0xFF1976D2) : Colors.grey,
                      size: 36,
                    ),
                    onPressed: _toggleLike,
                  )
                ],
              ),
              Text(
                'Posted on: ${DateFormat('yyyy-MM-dd').format((postData['timestamp'] as Timestamp).toDate())}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
              ),
              const SizedBox(height: 3),
              const Divider(thickness: 1, color: Color(0xFF1976D2), height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
