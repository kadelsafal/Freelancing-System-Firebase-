// appointed_user_ui.dart
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/tabs/issues/issues_tabs.dart';
import 'package:freelance_system/Projects/tabs/milestone/milestone_tab.dart';

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/tabs/issues_tab.dart';

import 'package:freelance_system/Projects/tabs/status/status_tab.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'appointed_user_service.dart';

class AppointedUser extends StatefulWidget {
  final String projectId;
  final String appointedName;
  final String appointedType;
  final VoidCallback onAppointedUserRemoved;

  const AppointedUser({
    super.key,
    required this.projectId,
    required this.appointedName,
    required this.appointedType,
    required this.onAppointedUserRemoved,
  });

  @override
  State<AppointedUser> createState() => _AppointedUserState();
}

class _AppointedUserState extends State<AppointedUser>
    with TickerProviderStateMixin {
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

  Future<void> _removeAppointed() async {
    final confirmed =
        await showConfirmationDialog(context, widget.appointedType);
    if (!confirmed) return;

    final success = await removeAppointedUser(
      context: context,
      projectId: widget.projectId,
      appointedType: widget.appointedType,
    );

    if (success) {
      widget.onAppointedUserRemoved();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Appointed ${widget.appointedType.capitalize()}");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Appointed ${widget.appointedType.capitalize()}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text(
                widget.appointedName.isNotEmpty ? widget.appointedName[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.appointedName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: _removeAppointed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Remove ${widget.appointedType.capitalize()}"),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        Consumer<Userprovider>(
          builder: (context, userProvider, _) {
            final currentUserName = userProvider.userName;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('statusUpdates')
                  .snapshots(),
              builder: (context, snapshot) {
                int unseenCount =
                    calculateUnseenStatusCount(snapshot, currentUserName);

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
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ]
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
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: SizedBox(
            height: 800,
            child: TabBarView(
              controller: _tabController,
              children: [
                MilestoneTab(projectId: widget.projectId),
                IssuesTab(projectId: widget.projectId, role: 'client'),
                StatusTab(projectId: widget.projectId, role: 'client'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
