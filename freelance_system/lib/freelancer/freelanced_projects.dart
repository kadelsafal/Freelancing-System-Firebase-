import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/recommendtab.dart';
import 'package:freelance_system/freelancer/appliedproject.dart';
import 'package:freelance_system/freelancer/projectscreen.dart';
import 'package:freelance_system/freelancer/recommended.dart';
import 'package:freelance_system/freelancer/teambuilding.dart';
import 'package:googleapis/content/v2_1.dart';

class FreelancedProjects extends StatefulWidget {
  const FreelancedProjects({super.key});

  @override
  State<FreelancedProjects> createState() => _FreelancedProjectsState();
}

class _FreelancedProjectsState extends State<FreelancedProjects>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0), // Ensures proper spacing
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: "Projects"),
              Tab(text: "Recommendation"),
              Tab(text: "Applied Projects"),
              Tab(text: "Team Building")
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // Ensures TabBarView takes up remaining space
            child: Align(
              alignment: Alignment.center,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: FreelancerProjectscreen(),
                  ),
                  SingleChildScrollView(
                    child: Recommend(),
                  ),
                  SingleChildScrollView(
                    child: Appliedproject(),
                  ),
                  SingleChildScrollView(
                    child: Teambuilding(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
