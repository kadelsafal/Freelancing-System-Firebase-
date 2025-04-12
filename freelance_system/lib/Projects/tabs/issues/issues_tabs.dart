import 'package:flutter/material.dart';
import 'issues_tabs_wrapper.dart';
import 'issues_form.dart';

class IssuesTab extends StatelessWidget {
  final String projectId;
  final String role;

  const IssuesTab({super.key, required this.projectId, required this.role});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IssuesTabBar(projectId: projectId, role: role),
            const SizedBox(height: 10),
            Expanded(child: IssuesTabBarView(projectId: projectId, role: role)),
            IssuesForm(projectId: projectId, role: role),
          ],
        ),
      ),
    );
  }
}
