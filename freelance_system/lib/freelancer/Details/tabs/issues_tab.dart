import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';

class IssuesTab extends StatefulWidget {
  final String projectId;
  const IssuesTab({super.key, required this.projectId});

  @override
  _IssuesTabState createState() => _IssuesTabState();
}

class _IssuesTabState extends State<IssuesTab> {
  final TextEditingController _issueController = TextEditingController();
  String _selectedStatus = 'Not Solved';

  // Function to create an issue
  void _createIssue(String author, String projectId) async {
    String issueText = _issueController.text.trim();
    if (issueText.isEmpty) {
      // Handle empty issue text
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an issue description')),
      );
      return;
    }

    // Get the current timestamp
    Timestamp timestamp = Timestamp.now();

    // Create a new issue in Firestore
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId) // Use the passed projectId
        .collection('issues')
        .add({
      'author': author, // Use current logged-in user's name
      'issueText': issueText,
      'status': _selectedStatus,
      'timestamp': timestamp,
    });

    // Clear the text field after adding the issue
    _issueController.clear();
  }

  // Function to update the issue status
  void _updateStatus(String docId, String newStatus, String projectId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId) // Use the passed projectId
        .collection('issues')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;
    String projectId = widget.projectId; // Access projectId from widget

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Form for issue text
          TextField(
            controller: _issueController,
            decoration: InputDecoration(
              labelText: 'Describe the issue',
              border: OutlineInputBorder(),
              hintText: 'Enter details about the issue',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 10),

          // Button to submit the new issue
          ElevatedButton(
            onPressed: () {
              _createIssue(currentName, projectId); // Use projectId
            },
            child: const Text('Submit Issue'),
          ),
          SizedBox(height: 20),

          // StreamBuilder to display existing issues
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(projectId) // Use the correct projectId
                .collection('issues')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, issueSnapshot) {
              if (issueSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (issueSnapshot.hasError) {
                return Center(child: Text("Error: ${issueSnapshot.error}"));
              } else if (!issueSnapshot.hasData ||
                  issueSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No issues created"));
              } else {
                return Expanded(
                  child: ListView(
                    children: issueSnapshot.data!.docs.map((doc) {
                      var issueData = doc.data() as Map<String, dynamic>;
                      String status = issueData['status'] ?? 'Not Solved';

                      // Determine the color based on status
                      Color statusColor;
                      if (status == 'Solved') {
                        statusColor = Colors.green;
                      } else if (status == 'Solving') {
                        statusColor = Colors.white;
                      } else {
                        statusColor = Colors.red;
                      }

                      return ListTile(
                        title: Text(issueData['author']),
                        subtitle: Text(issueData['issueText']),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: status,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _updateStatus(doc.id, newValue,
                                    projectId); // Pass projectId
                              }
                            },
                            items: <String>['Not Solved', 'Solving', 'Solved']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
