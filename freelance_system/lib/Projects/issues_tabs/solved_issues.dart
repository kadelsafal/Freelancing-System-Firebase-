import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/tabs/fullscreenimage.dart';

class SolvedIssues extends StatefulWidget {
  final String projectId;
  final String role;
  const SolvedIssues({super.key, required this.projectId, required this.role});

  @override
  State<SolvedIssues> createState() => _SolvedIssuesState();
}

class _SolvedIssuesState extends State<SolvedIssues> {
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Solved':
        return Colors.green; // Green for 'Solved'
      case 'Not Solved':
        return Colors.red; // Red for 'Not Solved'
      default:
        return Colors.white;
    }
  }

  // Helper function to get the text color based on status
  Color _getStatusTextColor(String status) {
    if (status == 'Not Solved') {
      return Colors.white;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display all issues first
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('issues')
                .where('status', isEqualTo: 'Solved')
                .orderBy('timestamp',
                    descending: false) // Fetch latest issue at the bottom
                .snapshots(),
            builder: (context, issueSnapshot) {
              if (issueSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (issueSnapshot.hasError) {
                return Center(child: Text("Error: ${issueSnapshot.error}"));
              } else if (!issueSnapshot.hasData ||
                  issueSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No issues found"));
              } else {
                return ListView(
                  shrinkWrap: true, // Prevent infinite height
                  children: issueSnapshot.data!.docs.map((doc) {
                    var issueData = doc.data() as Map<String, dynamic>;

                    // Check if 'imageUrls' is null and set it to an empty list if it is
                    List<String> imageUrls = issueData['imageUrls'] != null
                        ? List<String>.from(issueData['imageUrls'])
                        : [];

                    // Fullscreen image viewing functionality
                    void _showFullScreenImage(String url) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(url: url),
                        ),
                      );
                    }

                    // Handle status change
                    void _changeStatus(String status) {
                      FirebaseFirestore.instance
                          .collection('projects')
                          .doc(widget.projectId)
                          .collection('issues')
                          .doc(doc.id)
                          .update({'status': status});
                    }

                    // Get timestamp and format it
                    var timestamp =
                        (issueData['timestamp'] as Timestamp).toDate();
                    String formattedTime =
                        "${timestamp.hour}:${timestamp.minute}, ${timestamp.day}/${timestamp.month}/${timestamp.year}";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      elevation: 5,
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  child: Text(
                                    issueData['author'][0],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  // <-- Prevents overflow in case of long names
                                  child: Text(
                                    issueData['author'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              issueData['issueText'],
                              style: const TextStyle(fontSize: 14),
                              softWrap: true, // Ensure wrapping
                            ),
                            const SizedBox(height: 5),

                            // Images
                            if (imageUrls.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: imageUrls.map((url) {
                                    return GestureDetector(
                                      onTap: () => _showFullScreenImage(url),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Image.network(
                                          url,
                                          width: 120,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                            Text(
                              "Posted on: $formattedTime",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (issueData['role'] == widget.role)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(issueData['status']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: issueData['status'],
                                  dropdownColor:
                                      _getStatusColor(issueData['status']),
                                  iconEnabledColor:
                                      _getStatusTextColor(issueData['status']),
                                  underline:
                                      const SizedBox(), // Remove underline
                                  style: TextStyle(
                                    color: _getStatusTextColor(
                                        issueData['status']),
                                  ),
                                  onChanged: (newStatus) {
                                    if (newStatus != null)
                                      _changeStatus(newStatus);
                                  },
                                  items: const [
                                    DropdownMenuItem<String>(
                                      value: 'Solving',
                                      child: Text('Solving'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Solved',
                                      child: Text('Solved'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Not Solved',
                                      child: Text('Not Solved'),
                                    ),
                                  ],
                                ),
                              ),
                            if (issueData['role'] != widget.role)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(issueData['status']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  issueData['status'] ?? 'Solving',
                                  style: TextStyle(
                                    color: _getStatusTextColor(
                                        issueData['status']),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
