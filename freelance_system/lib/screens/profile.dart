import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:freelance_system/dashboard_controller/mydrawer.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/profile_controller/posttab.dart';
import '../profile_controller/bottomsheet_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Userprovider>(context, listen: false).getUserDetails();
    });
  }

  String getRatingText(double rating) {
    if (rating >= 4.5) return "Excellent";
    if (rating >= 3.5) return "Good";
    if (rating >= 2.5) return "Average";
    if (rating >= 1.5) return "Beginner";
    return "Poor";
  }

  double getExperienceRating(int yearsOfExperience) {
    if (yearsOfExperience >= 10) {
      return 5.0;
    } else if (yearsOfExperience >= 5) {
      return 4.0;
    } else if (yearsOfExperience >= 2) {
      return 3.0;
    } else if (yearsOfExperience >= 1) {
      return 2.0;
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);
    int yearsOfExperience = int.tryParse(userProvider.yearsOfExperience) ?? 0;
    double experienceRating = getExperienceRating(yearsOfExperience);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Profile",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.blue),
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade50,
                backgroundImage:
                    (userProvider.profileimage?.isNotEmpty ?? false)
                        ? NetworkImage(userProvider.profileimage!)
                        : null,
                child: (userProvider.profileimage?.isEmpty ?? true)
                    ? Text(
                        userProvider.userName.isNotEmpty
                            ? userProvider.userName[0]
                            : "?",
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userProvider.userName.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return BottomsheetProfile();
                    }).then((value) async {
                  // If the bottom sheet was closed with a successful update
                  if (value == true) {
                    // Refresh the profile screen
                    await Provider.of<Userprovider>(context, listen: false)
                        .getUserDetails();
                    if (mounted) {
                      setState(() {});
                    }
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                profileStat(userProvider.followers, "Followers"),
                verticalDivider(),
                profileStat(userProvider.followed, "Followed"),
                verticalDivider(),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .where('userId', isEqualTo: userProvider.userId)
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int completedProjects =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return profileStat(
                        completedProjects.toString(), "Projects");
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  "Your Rating:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                RatingBar.builder(
                  initialRating: experienceRating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemSize: 20,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, size: 20, color: Colors.amber),
                  onRatingUpdate: (rating) async {
                    await userProvider.updateUserRating(rating);
                    if (mounted) {
                      setState(() {
                        userProvider.yearsOfExperience =
                            yearsOfExperience.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  getRatingText(experienceRating),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  "Rated: ${experienceRating.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            const SizedBox(height: 20),
            const PostTab(),
          ],
        ),
      ),
    );
  }

  Widget profileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget verticalDivider() {
    return Container(
      height: 40,
      width: 3,
      color: Colors.blue.shade200,
    );
  }
}
