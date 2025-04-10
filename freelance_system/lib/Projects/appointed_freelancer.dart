import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/tabs/issues_tab.dart';
import 'package:freelance_system/Projects/tabs/milestone_tab.dart';
import 'package:freelance_system/Projects/tabs/status_tab.dart';

// Extension to capitalize strings
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AppointedUser extends StatefulWidget {
  final String projectId;
  final String appointedName;
  final String appointedType; // 'freelancer' or 'team'
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

  Future<void> _clearSubCollection(String collectionName) async {
    try {
      // Get all documents in the sub-collection
      var querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection(collectionName)
          .get();

      // Delete each document in the sub-collection
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Handle error if needed
      print("Error clearing $collectionName: $e");
    }
  }

  Future<void> _removeAppointed() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove Appointed ${widget.appointedType.capitalize()}"),
        content: Text(
            "Are you sure you want to remove the appointed ${widget.appointedType}?"),
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
      final updateData = widget.appointedType == 'Freelancer'
          ? {
              'appointedFreelancer': null,
              'appointedFreelancerId': null,
              'status': 'New'
            }
          : {'appointedTeam': null, 'appointedTeamId': null, 'status': 'New'};

      try {
        // Update project data to remove appointed freelancer/team
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update(updateData);

        // Empty the sub-collections: issues, statusUpdates, milestones
        await Future.wait([
          _clearSubCollection('issues'),
          _clearSubCollection('statusUpdates'),
          _clearSubCollection('milestones'),
        ]);

        widget.onAppointedUserRemoved();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Appointed ${widget.appointedType.capitalize()} removed successfully."),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Error removing appointed ${widget.appointedType.capitalize()}: $e"),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 50,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Milestone"),
              Tab(text: "Issues"),
              Tab(text: "Status"),
            ],
          ),
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
                StatusTab(projectId: widget.projectId, role: 'Client'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
