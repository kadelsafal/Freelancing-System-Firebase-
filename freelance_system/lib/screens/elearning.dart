import 'package:flutter/material.dart';
import 'package:freelance_system/learning/allcourses.dart';
import 'package:freelance_system/learning/mycourses.dart';

class LearningHub extends StatefulWidget {
  const LearningHub({super.key});

  @override
  State createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            "E-Learning Hub",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: Color(0xFF0D47A1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(text: "All Courses"),
                  Tab(text: "My Courses"),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Allcourses(),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: MyCourses(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
