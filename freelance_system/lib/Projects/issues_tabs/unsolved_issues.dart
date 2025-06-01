import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/profile_controller/imageslider.dart';

class UnsolvedIssues extends StatefulWidget {
  final String projectId;
  final String role;
  const UnsolvedIssues(
      {super.key, required this.projectId, required this.role});

  @override
  State<UnsolvedIssues> createState() => _UnsolvedIssuesState();
}

class _UnsolvedIssuesState extends State<UnsolvedIssues> {
  // ScrollController to scroll to the bottom when new data is added
  ScrollController _scrollController = ScrollController();
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
                .where('status', isEqualTo: 'Not Solved')
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
                // Scroll to the bottom when new data is added
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView(
                  controller: _scrollController,
                  shrinkWrap: true, // Prevent infinite height
                  children: issueSnapshot.data!.docs.map((doc) {
                    var issueData = doc.data() as Map<String, dynamic>;

                    // Check if 'imageUrls' is null and set it to an empty list if it is
                    List<String> imageUrls = issueData['imageUrls'] != null
                        ? List<String>.from(issueData['imageUrls'])
                        : [];

                    // Fullscreen image viewing functionality

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
                                  backgroundColor: const Color(0xFF1976D2),
                                  child: Text(
                                    issueData['author'][0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (issueData['role'] == widget.role)
                                  Container(
                                    padding: const EdgeInsets.only(
                                        left: 2, right: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          _getStatusColor(issueData['status']),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<String>(
                                      value: issueData['status'],
                                      dropdownColor:
                                          _getStatusColor(issueData['status']),
                                      iconEnabledColor: _getStatusTextColor(
                                          issueData['status']),
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
                                      color:
                                          _getStatusColor(issueData['status']),
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
                            const SizedBox(
                              height: 10,
                            ),
                            // Images
                            if (imageUrls.isNotEmpty)
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Imageslider(
                                  heightFactor: 0.2,
                                  imageWidth: 400,
                                  imageUrls: imageUrls,
                                ),
                              ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Posted on: $formattedTime",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
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
