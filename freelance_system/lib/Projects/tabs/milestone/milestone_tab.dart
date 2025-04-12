import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/tabs/milestone/addmilestone.dart';
import 'milestone_service.dart';
import 'milestone_ui.dart';
import 'milestone_utils.dart';

class MilestoneTab extends StatefulWidget {
  final String projectId;

  const MilestoneTab({super.key, required this.projectId});

  @override
  State<MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<MilestoneTab> {
  final TextEditingController urlController = TextEditingController();
  List<String> projectUrls = [];
  late MilestoneService _milestoneService;

  @override
  void initState() {
    super.initState();
    _milestoneService = MilestoneService(widget.projectId);
    _loadProjectUrls();
  }

  Future<void> _loadProjectUrls() async {
    final urls = await _milestoneService.loadProjectUrls();
    setState(() {
      projectUrls = urls;
    });
  }

  void _showUrlDialog() {
    urlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attach Project URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'Enter Drive URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newUrl = urlController.text;
              if (newUrl.isNotEmpty) {
                if (!newUrl.startsWith('http://') &&
                    !newUrl.startsWith('https://')) {
                  newUrl = 'https://$newUrl';
                }
                if (projectUrls.length < 5) {
                  await _milestoneService.addProjectUrl(projectUrls, newUrl);
                  _loadProjectUrls();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('You can only add up to 5 URLs.')),
                  );
                }
              }
            },
            child: const Text("Attach URL"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DocumentSnapshot milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _milestoneService.deleteMilestone(milestone);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MilestoneUI.buildUrlSection(context, projectUrls, _showUrlDialog),
        const SizedBox(height: 25),
        MilestoneUI.buildAddMilestoneButton(() {
          showDialog(
            context: context,
            builder: (_) => Addmilestone(projectId: widget.projectId),
          );
        }),
        const SizedBox(height: 25),
        MilestoneUI.buildMilestoneHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _milestoneService.getMilestonesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final milestones = snapshot.data!.docs;
              final progress =
                  MilestoneUtils.calculateProjectProgress(milestones);
              final stats = MilestoneUtils.calculateMilestoneStats(milestones);

              return ListView(
                children: [
                  ...milestones.asMap().entries.map((entry) {
                    return MilestoneUI.buildMilestoneItem(
                      milestoneIndex: entry.key,
                      milestone: entry.value,
                      onStatusChanged: (index, status) {
                        _milestoneService.updateSubtaskStatus(
                            entry.value, index, status);
                      },
                      onDelete: () => _showDeleteConfirmation(entry.value),
                    );
                  }),
                  MilestoneUI.buildProjectProgressSection(progress),
                  MilestoneUI.buildStatsSection(stats),
                  const SizedBox(height: 25),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
