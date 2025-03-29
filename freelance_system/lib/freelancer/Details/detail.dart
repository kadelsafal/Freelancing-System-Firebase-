import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/freelancer/Details/applysheet.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool isExpanded = false;
  String _getWrappedTitle(String text, int wordsPerLine) {
    List<String> words = text.split(' ');
    List<String> wrappedLines = [];

    for (int i = 0; i < words.length; i += wordsPerLine) {
      wrappedLines.add(words
          .sublist(i,
              i + wordsPerLine > words.length ? words.length : i + wordsPerLine)
          .join(' '));
    }

    return wrappedLines.join('\n'); // Join with newline to wrap text
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;
    return Scaffold(
        appBar: AppBar(
          title: Text("Project Details"),
        ),
        body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("Project not found"));
              } else {
                var project = snapshot.data!;
                List<String> preferences =
                    List<String>.from(project['preferences'] ?? ['']);
                if (preferences.isEmpty) {
                  preferences = ["None"];
                }

                String title = project['title'] ?? '';
                String description = project['description'] ?? '';
                double budget = project['budget'] ?? '';
                String deadline = project['deadline'] ?? '';
                String projectId = project['projectId'] ?? '';
                List<dynamic> appliedIndividuals =
                    project['appliedIndividuals'] ?? [];
                int appliedCount = appliedIndividuals.length;

                // Check if the current user is in the appliedIndividuals list
                bool isApplied = appliedIndividuals
                    .any((applicant) => applicant['name'] == currentName);

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          maxLines: isExpanded ? null : 5,
                          softWrap: true,
                        ),
                        SizedBox(height: 5),
                        Text(
                          project['createdAt'] != null &&
                                  project['createdAt'] is Timestamp
                              ? 'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((project['createdAt'] as Timestamp).toDate())}'
                              : 'Posted on: N/A', // Handle null values gracefully
                          style: TextStyle(
                              fontSize: 12,
                              color: const Color.fromARGB(255, 78, 78, 78)),
                        ),
                        SizedBox(height: 25),
                        Text(
                          "Description",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 250, 231, 254),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(description),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Budget : ",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 106, 0, 148),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Deadline : $deadline",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 201, 0, 0),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Applied By : ",
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 130, 130, 130),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '$appliedCount',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            Icon(
                              Icons.person,
                              color: Colors.deepPurple,
                            )
                          ],
                        ),
                        SizedBox(height: 14),
                        Text("Preferences",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Wrap(
                          spacing: 4.0, // Space between each item
                          runSpacing: 4.0, // Space between lines when wrapping
                          children: preferences.map((preference) {
                            return Chip(
                              label: Text(
                                preference,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              padding: EdgeInsets.all(4),
                              backgroundColor: Colors.deepPurple
                                  .shade100, // Optional: Change color
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 14),
                        Center(
                          child: ElevatedButton(
                              onPressed: isApplied
                                  ? null // Disable button if already applied
                                  : () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (BuildContext context) {
                                          return ApplyModalSheet(
                                              projectId: projectId);
                                        },
                                      );
                                    },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    isApplied
                                        ? Colors.grey
                                        : Colors.deepPurple),
                                foregroundColor: WidgetStateProperty.all(
                                    isApplied ? Colors.black : Colors.white),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child:
                                    Text(isApplied ? "Applied" : "Apply Now"),
                              )),
                        )
                      ],
                    ),
                  ),
                );
              }
            }));
  }
}
