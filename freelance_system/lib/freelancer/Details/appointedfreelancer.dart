import 'package:flutter/material.dart';
import 'package:freelance_system/freelancer/Details/tabs/issues_tab.dart';
import 'package:freelance_system/freelancer/Details/tabs/milestone_tab.dart';
import 'package:freelance_system/freelancer/Details/tabs/status_tab.dart';

class AppointedFreelancerMessage extends StatefulWidget {
  final String projectId;

  const AppointedFreelancerMessage({super.key, required this.projectId});

  @override
  _AppointedFreelancerMessageState createState() =>
      _AppointedFreelancerMessageState();
}

class _AppointedFreelancerMessageState extends State<AppointedFreelancerMessage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TabBar
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              isScrollable: false, // Ensures full names fit
              tabs: const [
                Tab(text: "Issues"),
                Tab(text: "Status"),
                Tab(text: "Milestones"),
              ],
            ),
          ),

          // TabBarView inside ConstrainedBox
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 350,
            ),
            child: SizedBox(
              height: 650, // max height for TabBarView
              child: TabBarView(
                controller: _tabController,
                children: [
                  IssuesTab(
                    projectId: widget.projectId,
                  ),
                  StatusTab(
                    projectId: widget.projectId,
                  ),
                  const MilestoneTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
