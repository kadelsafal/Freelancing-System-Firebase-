import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'milestone_utils.dart';

class MilestoneUI {
  static Widget buildUrlSection(
      BuildContext context, List<String> projectUrls, VoidCallback onAddUrl) {
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
              onPressed: onAddUrl,
            ),
          ],
        ),
        if (projectUrls.isNotEmpty)
          Column(
            children: projectUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GestureDetector(
                  onTap: () => MilestoneUI._launchUrl(context, url),
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
      ],
    );
  }

  static Widget buildAddMilestoneButton(VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1976D2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Milestone'),
    );
  }

  static Widget buildMilestoneHeader() {
    return Column(
      children: [
        const SizedBox(height: 25),
        const Divider(),
        const SizedBox(height: 25),
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Milestones",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  static Widget buildMilestoneItem({
    required int milestoneIndex,
    required DocumentSnapshot milestone,
    required Function(int, String) onStatusChanged,
    required Function() onDelete,
  }) {
    final subtasks = List<Map<String, dynamic>>.from(milestone['subtasks']);
    final doneCount = subtasks.where((s) => s['status'] == 'Completed').length;

    return GestureDetector(
      onTap: onDelete,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Milestone ${milestoneIndex + 1}: ${milestone['title'].toString().toUpperCase()}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...subtasks.asMap().entries.map((entry) {
                int index = entry.key;
                var task = entry.value;
                return _buildSubtaskItem(task, index, onStatusChanged);
              }),
              _buildProgressBar(doneCount, subtasks.length),
              const SizedBox(height: 25),
              _buildStatusIndicator(milestone['status'] as String?),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSubtaskItem(Map<String, dynamic> task, int index,
      Function(int, String) onStatusChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task ${index + 1}: ${task['title']} ",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Start Date: ${MilestoneUtils.formatDate(task['startDate'])}",
                  style: const TextStyle(
                      fontSize: 14, color: Color.fromARGB(255, 0, 181, 60)),
                ),
                const SizedBox(height: 5),
                Text(
                  "End Date: ${MilestoneUtils.formatDate(task['endDate'])}",
                  style: const TextStyle(
                      fontSize: 14, color: Color.fromARGB(255, 174, 0, 0)),
                ),
                const SizedBox(height: 10),
              ],
            )
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildStatusDropdown(
              currentStatus: task['status'],
              onChanged: (status) => onStatusChanged(index, status!),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  static Widget _buildStatusDropdown({
    required String currentStatus,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: MilestoneUtils.getStatusColor(currentStatus),
        borderRadius: BorderRadius.circular(45),
        border: Border.all(
          color: MilestoneUtils.getStatusColor(currentStatus),
          width: 3,
        ),
      ),
      child: DropdownButton<String>(
        value: currentStatus,
        isDense: true,
        dropdownColor: MilestoneUtils.getStatusColor(currentStatus),
        iconEnabledColor: MilestoneUtils.getStatusTextColor(currentStatus),
        underline: const SizedBox(),
        style: TextStyle(
          color: MilestoneUtils.getStatusTextColor(currentStatus),
        ),
        onChanged: onChanged,
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
    );
  }

  static Widget _buildProgressBar(int doneCount, int totalTasks) {
    return LinearPercentIndicator(
      lineHeight: 8.0,
      percent: totalTasks == 0 ? 0 : doneCount / totalTasks,
      progressColor: Colors.green,
      backgroundColor: const Color.fromARGB(255, 94, 94, 94),
      barRadius: const Radius.circular(10),
      padding: EdgeInsets.zero,
    );
  }

  static Widget _buildStatusIndicator(String? status) {
    return Column(
      children: [
        Text(
          "Status: ${status ?? ''}",
          style: TextStyle(
            color: MilestoneUtils.getStatusTextColor(status),
          ),
        ),
        Row(
          children: [
            if (status == 'Completed')
              const Icon(Icons.check_circle, color: Colors.green),
            if (status == 'Not Completed')
              const Icon(Icons.cancel, color: Colors.red),
            if (status == 'In Process')
              const Icon(Icons.hourglass_empty, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              status == 'Completed'
                  ? 'Completed'
                  : status == 'Not Completed'
                      ? 'Not Completed'
                      : 'In Process',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildProjectProgressSection(double progress) {
    return Column(
      children: [
        const SizedBox(height: 25),
        const Center(
          child: Text("Overall Project Completion",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LinearPercentIndicator(
            lineHeight: 20.0,
            percent: progress,
            progressColor: const Color.fromARGB(255, 0, 171, 60),
            backgroundColor: Colors.grey.shade300,
            barRadius: const Radius.circular(10),
            center: Text("${(progress * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                    fontSize: 14, color: Color.fromARGB(255, 112, 112, 112))),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static Widget buildStatsSection(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                icon: Icons.list,
                color: Colors.blue,
                text: "Total Milestones: ${stats['total']}",
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                color: Colors.green,
                text: "Completed: ${stats['completed']}",
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                icon: Icons.cancel,
                color: Colors.red,
                text: "Not Completed: ${stats['notCompleted']}",
              ),
              _buildStatCard(
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                text: "In Process: ${stats['inprocess']}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("ERROR: Could not launch URL: $url");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch URL")),
        );
      }
    } catch (e) {
      print("ERROR: Exception while launching URL: $url");
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }
}
