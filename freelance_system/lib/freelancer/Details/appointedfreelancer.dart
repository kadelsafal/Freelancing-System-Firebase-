import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/tabs/issues/issues_tabs.dart';
import 'package:freelance_system/Projects/tabs/milestone/milestone_tab.dart';

import 'package:provider/provider.dart';
import '../../Projects/tabs/issues_tab.dart';
import '../../Projects/tabs/milestone_tab.dart';
import '../../Projects/tabs/status/status_tab.dart';
import '../../Projects/tabs/status_tab.dart';
import '../../providers/userProvider.dart';

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
  int _statusUnseenCount = 0;

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
          // StreamBuilder for unseen count
          Consumer<Userprovider>(
            builder: (context, userProvider, _) {
              final currentUserName = userProvider
                  .userName; // Assuming userProvider gives user name
              print("Current userName: $currentUserName");

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('statusUpdates')
                    .snapshots(),
                builder: (context, snapshot) {
                  int unseenCount = 0;

                  if (snapshot.hasData) {
                    final updates = snapshot.data!.docs;

                    // Iterate over the updates and calculate unseen messages for the current user
                    unseenCount = updates.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final seenBy = List<String>.from(data['isSeenBy'] ?? []);
                      final senderName = data['senderName'];

                      // Check if the current user's name is NOT in the 'isSeenBy' list and the message is not from the current user
                      bool isUnseen = senderName != currentUserName &&
                          !seenBy.contains(currentUserName);

                      // Print the senderName and unseen status for each message
                      print(
                          "Status senderName: $senderName, Unseen by $currentUserName: $isUnseen");

                      return isUnseen;
                    }).length;

                    // Print the unseen count for the current user
                    print("Unseen count for $currentUserName: $unseenCount");
                  }

                  return SizedBox(
                    height: 50,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.deepPurple,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        const Tab(text: "Milestone"),
                        const Tab(text: "Issues"),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Status"),
                              if (unseenCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unseenCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
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
