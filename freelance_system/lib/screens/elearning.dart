import 'package:flutter/material.dart';
import 'package:freelance_system/learning/allcourses.dart';
import 'package:freelance_system/learning/mycourses.dart';

class LearningHub extends StatefulWidget {
  const LearningHub({super.key});

  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("E-learning"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          toolbarHeight: 90,
          bottom: const TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                  width: 5.0, color: Colors.blue), // Increased thickness
              // Adds padding
            ),
            labelColor: Colors.white, // Active tab text color
            unselectedLabelColor:
                Colors.yellowAccent, // Inactive tab text color
            tabs: [
              Tab(
                child: Text(
                  "All Courses",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  "My Courses",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Allcourses(),
            MyCourses(),
          ],
        ),
      ),
    );
  }
}
