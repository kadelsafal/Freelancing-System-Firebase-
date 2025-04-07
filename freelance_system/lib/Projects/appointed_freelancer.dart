import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/tabs/issues_tab.dart';
import 'package:freelance_system/Projects/tabs/milestone_tab.dart';
import 'package:freelance_system/Projects/tabs/status_tab.dart';

class AppointedFreelancer extends StatefulWidget {
  final String appointedName;
  final String projectId;
  final VoidCallback onFreelancerRemoved;

  const AppointedFreelancer({
    super.key,
    required this.appointedName,
    required this.projectId,
    required this.onFreelancerRemoved,
  });

  @override
  State<AppointedFreelancer> createState() => _AppointedFreelancerState();
}

class _AppointedFreelancerState extends State<AppointedFreelancer>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Appointed Freelancer",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Remove Freelancer"),
                  content: const Text(
                      "Are you sure you want to remove the appointed freelancer?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Remove"),
                    ),
                  ],
                ),
              );

              if (confirm) {
                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .update({
                  'appointedFreelancer': '',
                  'appointedFreelancerID': '',
                });

                widget.onFreelancerRemoved();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Appointed freelancer removed")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Remove Freelancer"),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            isScrollable: false,
            tabs: const [
              Tab(text: "Issues"),
              Tab(text: "Status"),
              Tab(text: "Milestone"),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: SizedBox(
            height: 750,
            child: TabBarView(
              controller: _tabController,
              children: [
                IssuesTab(
                  projectId: widget.projectId,
                  role: 'client',
                ),
                StatusTab(
                  projectId: widget.projectId,
                  role: 'Client',
                ),
                const MilestoneTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
