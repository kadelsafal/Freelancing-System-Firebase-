import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Projects/tabs/issues_tab.dart';
import '../../Projects/tabs/milestone_tab.dart';
import '../../Projects/tabs/status_tab.dart';

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
  int unseenStatusCount = 0;
  Timestamp? latestStatusTimestamp;
  bool hasUnseenUpdates = false;

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

  // Check if there are new unseen updates based on the timestamp
  void checkUnseenUpdates(QuerySnapshot snapshot) {
    if (snapshot.docs.isNotEmpty) {
      Timestamp lastUpdateTimestamp = snapshot.docs.first['timestamp'];
      DateTime lastUpdateDate =
          lastUpdateTimestamp.toDate(); // Convert to DateTime

      if (latestStatusTimestamp == null ||
          lastUpdateDate.isAfter(latestStatusTimestamp! as DateTime)) {
        setState(() {
          hasUnseenUpdates = true; // There are new unseen updates
        });
      }
    }
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
              tabs: [
                const Tab(text: "Milestones"),
                const Tab(text: "Issues"),
                Tab(
                  text: "Status",
                  icon: unseenStatusCount > 0
                      ? Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unseenStatusCount',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // TabBarView inside ConstrainedBox
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 350,
            ),
            child: SizedBox(
              height: 750, // max height for TabBarView
              child: TabBarView(
                controller: _tabController,
                children: [
                  MilestoneTab(projectId: widget.projectId),
                  IssuesTab(
                    projectId: widget.projectId,
                    role: "freelancer",
                  ),
                  StatusTab(
                    projectId: widget.projectId,
                    role: "freelancer",
                    onNewUpdates: checkUnseenUpdates,
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
