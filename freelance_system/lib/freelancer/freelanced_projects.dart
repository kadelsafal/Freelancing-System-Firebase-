import 'package:flutter/material.dart';
import 'package:freelance_system/freelancer/appliedproject.dart';
import 'package:freelance_system/freelancer/projectscreen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Projects"),
            Tab(text: "Applied Projects"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FreelancerProjectscreen(), // Projects tab content
          Appliedproject(), // Applied Projects tab content
        ],
      ),
    );
  }
}
