import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/issues_tabs/all_issues.dart';
import 'package:freelance_system/Projects/issues_tabs/solved_issues.dart';
import 'package:freelance_system/Projects/issues_tabs/unsolved_issues.dart';

class IssuesTabBar extends StatefulWidget {
  final String projectId;
  final String role;

  const IssuesTabBar({super.key, required this.projectId, required this.role});

  @override
  State<IssuesTabBar> createState() => _IssuesTabBarState();
}

class _IssuesTabBarState extends State<IssuesTabBar> {
  int _unsolvedIssuesCount = 0;

  Future<void> _countUnsolvedIssues() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('issues')
        .where('status', isEqualTo: 'Not Solved')
        .get();
    if (!mounted) return; // 🔒 Prevent setState after dispose
    setState(() {
      _unsolvedIssuesCount = snapshot.docs.length;
    });
    print("Unsolved Issues Count: $_unsolvedIssuesCount");
  }

  @override
  void initState() {
    super.initState();
    _countUnsolvedIssues();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('issues')
          .where('status', isEqualTo: 'Not Solved')
          .snapshots(),
      builder: (context, snapshot) {
        int unsolvedCount = 0;
        if (snapshot.hasData) {
          unsolvedCount = snapshot.data!.docs.length;
        }

        return TabBar(
          tabs: [
            const Tab(text: 'All Issues'),
            const Tab(text: 'Solved'),
            Tab(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Unsolved'),
                  ),
                  if (unsolvedCount > 0)
                    Positioned(
                      right: 0,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unsolvedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class IssuesTabBarView extends StatelessWidget {
  final String projectId;
  final String role;

  const IssuesTabBarView(
      {super.key, required this.projectId, required this.role});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        AllIssues(projectId: projectId, role: role),
        SolvedIssues(projectId: projectId, role: role),
        UnsolvedIssues(projectId: projectId, role: role),
      ],
    );
  }
}
