import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../profile_controller/showAddPostDialog.dart';
import '../profile_controller/mypost.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/providers/userProvider.dart';

class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Post Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add a Status / Post",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius:
                        20, // This should match the width/height of the container
                    backgroundColor: Colors.blue.shade900,
                    backgroundImage: (userProvider.profileimage?.isNotEmpty ??
                            false)
                        ? NetworkImage(userProvider.profileimage!)
                        : null, // Display the profile image if available and not empty
                    child: (userProvider.profileimage?.isEmpty ?? true)
                        ? Text(
                            userProvider.userName.isNotEmpty
                                ? userProvider.userName[0]
                                : "?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null, // If there's a profile image, no need to display the initial
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return ShowAddPostDialog();
                          },
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What's on your mind?",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 40),

        // User Posts Section
        MyPost(
            userId: userProvider.userId,
            isOwnProfile:
                FirebaseAuth.instance.currentUser!.uid == userProvider.userId),
      ],
    );
  }
}
