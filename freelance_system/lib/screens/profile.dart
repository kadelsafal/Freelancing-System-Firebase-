import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:freelance_system/profile_controller/experiencetab.dart';
import 'package:freelance_system/profile_controller/posttab.dart';
import '../profile_controller/bottomsheet_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Userprovider>(context, listen: false).getUserDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String getRatingText(double rating) {
    if (rating >= 4.5) return "Excellent";
    if (rating >= 3.5) return "Good";
    if (rating >= 2.5) return "Average";
    if (rating >= 1.5) return "Beginner";
    return "Poor";
  }

  // This method returns rating based on years of experience
  double getExperienceRating(int yearsOfExperience) {
    if (yearsOfExperience >= 10) {
      return 5.0; // 5 stars for 10+ years of experience
    } else if (yearsOfExperience >= 5) {
      return 4.0; // 4 stars for 5-9 years of experience
    } else if (yearsOfExperience >= 2) {
      return 3.0; // 3 stars for 2-4 years of experience
    } else if (yearsOfExperience >= 1) {
      return 2.0; // 2 stars for 1 year of experience
    } else {
      return 0.0; // No experience or 0 years, 0 stars
    }
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    // Safely convert yearsOfExperience from String to int
    int yearsOfExperience = int.tryParse(userProvider.yearsOfExperience) ?? 0;

    // Get the rating based on years of experience
    double experienceRating = getExperienceRating(yearsOfExperience);

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                userProvider.userName.isNotEmpty
                    ? userProvider.userName[0]
                    : "?",
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 20),
            Text(
              userProvider.userName.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return BottomsheetProfile();
                    });
              },
              child: Text("Edit Profile"),
            ),
            SizedBox(height: 20),

            // Followers, Followed, and Projects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                profileStat(userProvider.followers, "Followers"),
                verticalDivider(),
                profileStat(userProvider.followed, "Followed"),
                verticalDivider(),
                profileStat("10", "Projects"),
              ],
            ),
            SizedBox(height: 20),

            // Rating Section based on years of experience
            Column(
              children: [
                Text("Your Rating: ",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                RatingBar.builder(
                  initialRating: experienceRating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemSize: 20,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                  itemBuilder: (context, _) =>
                      Icon(Icons.star, size: 20, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      // Here, update the yearsOfExperience (as int)
                      userProvider.yearsOfExperience =
                          yearsOfExperience.toString();
                    });
                  },
                ),
                SizedBox(height: 10),
                Text(getRatingText(experienceRating),
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Rated: ${experienceRating.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
              ],
            ),

            // TabBar
            Padding(
              padding: const EdgeInsets.only(left: 18.0, right: 18.0),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold), // Bold tab text
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                      width: 3.0,
                      color: Colors.deepPurple), // Thicker indicator
                ),
                indicatorSize: TabBarIndicatorSize
                    .tab, // Ensures the indicator is equal to the tab width
                tabs: [
                  Tab(text: "Posts"),
                  Tab(text: "Experience"),
                ],
              ),
            ),

            // TabBarView
            SizedBox(
              height: 400, // Adjust based on content
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 20.0, left: 7.0, right: 7.0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PostTab(),
                    ExperienceTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label),
      ],
    );
  }

  Widget verticalDivider() {
    return Container(height: 40, width: 3, color: Colors.grey);
  }
}
