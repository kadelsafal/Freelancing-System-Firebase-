//Part 1
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/tabs/dialog_milestone.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MilestoneTab extends StatefulWidget {
  final String projectId;

  const MilestoneTab({super.key, required this.projectId});

  @override
  State<MilestoneTab> createState() => _MilestoneTabState();
}

class _MilestoneTabState extends State<MilestoneTab> {
  final TextEditingController urlController = TextEditingController();
  List<String> projectUrls = [];

  @override
  void initState() {
    super.initState();
    _loadProjectUrls();
  }

  Future<void> _loadProjectUrls() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    final data = doc.data();
    if (data != null && data.containsKey('urls')) {
      setState(() {
        projectUrls = List<String>.from(data['urls']);
      });
    }
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
                  newUrl = 'https://$newUrl'; // Add 'https://' if not present
                }
                if (projectUrls.length < 5) {
                  projectUrls.add(newUrl);
                  await FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.projectId)
                      .update({'urls': projectUrls});
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

  double _calculateProjectProgress(List<DocumentSnapshot> milestones) {
    if (milestones.isEmpty) return 0;
    double total = 0;

    for (var milestone in milestones) {
      final tasks = List<Map<String, dynamic>>.from(milestone['subtasks']);
      if (tasks.isNotEmpty) {
        final done = tasks.where((e) => e['status'] == 'Completed').length;
        total += done / tasks.length;
      }
    }

    return total / milestones.length;
  }

  void _toggleSubtaskStatus(
      DocumentSnapshot milestone, int index, String status) async {
    final updatedSubtasks =
        List<Map<String, dynamic>>.from(milestone['subtasks']);
    updatedSubtasks[index]['status'] = status;

    final completedCount =
        updatedSubtasks.where((s) => s['status'] == 'Completed').length;
    final taskStatus = completedCount == 0
        ? 'Not Completed'
        : completedCount == updatedSubtasks.length
            ? 'Completed'
            : 'In Process';

    await milestone.reference.update({
      'subtasks': updatedSubtasks,
      'status': taskStatus,
    });
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the URL.')),
      );
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "";
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is DateTime
            ? rawDate
            : DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green; // Green for 'Solved'
      case 'Not Completed':
        return Colors.red; // Red for 'Not Solved'
      default:
        return Colors.white;
    }
  }

  // Helper function to get the text color based on status
  Color _getStatusTextColor(String status) {
    if (status == 'Not Completed' || status == 'Completed') {
      return Colors.white;
    }
    return Colors.black;
  }

  // Helper function to calculate the milestone status stats
  Map<String, int> _calculateMilestoneStats(List<DocumentSnapshot> milestones) {
    int completedCount = 0;
    int notCompletedCount = 0;
    int inprocessCount = 0;
    int totalCount = milestones.length;

    for (var milestone in milestones) {
      if (milestone['status'] == 'Completed') {
        completedCount++;
      } else if (milestone['status'] == 'Not Completed') {
        notCompletedCount++;
      } else if (milestone['status'] == 'In Process') {
        inprocessCount++;
      }
    }

    return {
      'total': totalCount,
      'completed': completedCount,
      'notCompleted': notCompletedCount,
      'inprocess': inprocessCount
    };
  }

  void _deleteMilestone(DocumentSnapshot milestone) async {
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
              await milestone.reference.delete(); // Delete from Firestore
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Part 2
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Attach Project URL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: _showUrlDialog,
            ),
          ],
        ),
        if (projectUrls.isNotEmpty)
          Column(
            children: projectUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GestureDetector(
                  onTap: () => _launchUrl(url),
                  child: Text(
                    url,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        const Divider(),
        SizedBox(
          height: 25,
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple, // Text color (white)
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 20), // Padding
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold, // Bold text
              fontSize: 16, // Font size
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => MilestoneDialog(projectId: widget.projectId),
            );
          },
          icon: const Icon(
            Icons.add, // Add icon
            color: Colors.white, // Icon color (white)
          ),
          label: const Text('Add Milestone'),
        ),
        SizedBox(
          height: 25,
        ),
        const Divider(),
        SizedBox(
          height: 25,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text("Milestones",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(
          height: 25,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('milestones')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final milestones = snapshot.data!.docs;
              final progress = _calculateProjectProgress(milestones);
              final stats = _calculateMilestoneStats(milestones);

              return ListView(
                children: [
                  ...milestones.asMap().entries.map((entry) {
                    int milestoneIndex = entry.key;
                    var milestone = entry.value;

                    final subtasks =
                        List<Map<String, dynamic>>.from(milestone['subtasks']);
                    final doneCount = subtasks
                        .where((s) => s['status'] == 'Completed')
                        .length;

                    return GestureDetector(
                      onTap: () =>
                          _deleteMilestone(milestone), // Trigger delete on tap
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Milestone ${milestoneIndex + 1}: ${milestone['title'].toString().toUpperCase()}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              ...subtasks.asMap().entries.map((entry) {
                                int index = entry.key;
                                var task = entry.value;

                                // Dropdown for status (Editable for all users)
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Task ${index + 1}: ${task['title']} ",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Start Date: ${_formatDate(task['startDate'])}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: const Color.fromARGB(
                                                      255, 0, 181, 60)),
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Text(
                                              "End Date: ${_formatDate(task['endDate'])}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: const Color.fromARGB(
                                                      255, 174, 0, 0)),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(task[
                                                'status']), // Background color based on status
                                            borderRadius: BorderRadius.circular(
                                                45), // Rounded corners for the border
                                            border: Border.all(
                                              color: _getStatusTextColor(task[
                                                  'status']), // Border color based on status
                                              width: 3, // Border width
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: task['status'],
                                            isDense: true,
                                            dropdownColor:
                                                _getStatusColor(task['status']),
                                            iconEnabledColor:
                                                _getStatusTextColor(
                                                    task['status']),
                                            underline:
                                                const SizedBox(), // Remove underline
                                            style: TextStyle(
                                              color: _getStatusTextColor(
                                                  task['status']),
                                            ),
                                            onChanged: (status) {
                                              if (status != null) {
                                                _toggleSubtaskStatus(
                                                    milestone, index, status);
                                              }
                                            },
                                            items: const [
                                              DropdownMenuItem<String>(
                                                value: 'Completed',
                                                child: Text('Completed'),
                                              ),
                                              DropdownMenuItem<String>(
                                                value: 'Not Completed',
                                                child: Text('Not Completed'),
                                              ),
                                              DropdownMenuItem<String>(
                                                value: 'In Process',
                                                child: Text('In Process'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    )
                                  ],
                                );
                              }),
                              LinearPercentIndicator(
                                lineHeight: 8.0, // Height of the progress bar
                                percent: subtasks.isEmpty
                                    ? 0
                                    : doneCount /
                                        subtasks
                                            .length, // Percent value of progress
                                progressColor: Colors
                                    .green, // Green color for the progress
                                backgroundColor: const Color.fromARGB(
                                    255, 94, 94, 94), // Grey background color
                                barRadius: Radius.circular(
                                    10), // Circular border radius
                                padding: EdgeInsets.all(
                                    0), // Remove any padding for better appearance
                              ),
                              SizedBox(
                                height: 25,
                              ),
                              Text(
                                "Status: ${milestone['status']}",
                                style: TextStyle(
                                  color: _getStatusTextColor(milestone[
                                      'status']), // Dynamically change text color based on status
                                ),
                              ),
                              Row(
                                children: [
                                  // Conditional rendering based on status
                                  if (milestone['status'] == 'Completed')
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors
                                          .green, // Green check for completed
                                    ),
                                  if (milestone['status'] == 'Not Completed')
                                    Icon(
                                      Icons.cancel,
                                      color: Colors
                                          .red, // Red cross for not completed
                                    ),
                                  if (milestone['status'] == 'In Process')
                                    Icon(
                                      Icons.hourglass_empty,
                                      color: Colors
                                          .orange, // Orange hourglass for in process
                                    ),
                                  SizedBox(
                                      width: 8), // Space between text and icon
                                  Text(
                                    milestone['status'] == 'Completed'
                                        ? 'Completed'
                                        : milestone['status'] == 'Not Completed'
                                            ? 'Not Completed'
                                            : 'In Process',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 25),
                  Center(
                    child: Text("Overall Project Completion",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LinearPercentIndicator(
                      lineHeight: 20.0,
                      percent: progress,
                      progressColor: const Color.fromARGB(255, 0, 171, 60),
                      backgroundColor: Colors.grey.shade300,
                      barRadius: Radius.circular(10),
                      center: Text("${(progress * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 112, 112, 112))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Row for Total Milestones and Completed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.list, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Total Milestones: ${stats['total']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.green, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Completed: ${stats['completed']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: 15,
                        ),
                        // Row for Not Completed and In Process
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Not Completed: ${stats['notCompleted']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.orange, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_empty,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    "In Process: ${stats['inprocess']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(
          height: 25,
        ),
      ],
    );
  }
}
