import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';
import 'package:freelance_system/Projects/tabs/status/status_service.dart';
import 'package:intl/intl.dart';

class StatusCard extends StatelessWidget {
  final String statusId;
  final String projectId;
  final Map<String, dynamic> data;
  final String currentUser;

  const StatusCard({
    super.key,
    required this.statusId,
    required this.projectId,
    required this.data,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isSender = data['author'] == currentUser;
    final isSeen = (data['isSeenBy'] ?? []).contains(currentUser);

    if (!isSender && !isSeen) {
      StatusService.markAsSeen(
          projectId, statusId, data['isSeenBy'], currentUser);
    }

    // Format the timestamp
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final formattedTime = DateFormat('MMM dd, yyyy h:mm a')
        .format(timestamp); // e.g., "Apr 12, 2025 5:30 PM"

    return GestureDetector(
      onDoubleTap: () async {
        if (isSender) {
          final confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Status'),
              content:
                  const Text('Are you sure you want to delete this status?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete')),
              ],
            ),
          );
          if (confirm == true) {
            await StatusService.deleteStatus(projectId, statusId);
          }
        }
      },
      child: Padding(
        // Padding to add space between each card
        padding: const EdgeInsets.symmetric(
            vertical: 8), // Vertical space between each card
        child: Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.7), // Limiting width to 80% of screen width
            decoration: BoxDecoration(
              color: isSender
                  ? Colors.blue.shade100
                  : isSeen
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1976D2),
                      child: Text(
                        data['author'][0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(data['author'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (!isSender && !isSeen)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text("🟢 Unseen",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if ((data['text'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(data['text']),
                ],
                if (data['images'] != null && data['images'].isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Imageslider(
                        heightFactor: 0.2,
                        imageWidth: 200,
                        imageUrls: List<String>.from(data['images']),
                      ),
                    ),
                  ),
                ],
                // Displaying the timestamp below the images or text
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Posted on: $formattedTime',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                Wrap(
                  spacing: 4,
                  children: (data['isSeenBy'] ?? [])
                      .where((name) => name != data['author'])
                      .map<Widget>((name) {
                    return CircleAvatar(
                        radius: 8,
                        child: Text(name[0],
                            style: const TextStyle(fontSize: 10)));
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
