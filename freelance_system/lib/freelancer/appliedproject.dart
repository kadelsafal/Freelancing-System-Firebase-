import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/description.dart';
import 'package:freelance_system/freelancer/Details/detail.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Appliedproject extends StatefulWidget {
  const Appliedproject({super.key});

  @override
  State<Appliedproject> createState() => _AppliedprojectState();
}

class _AppliedprojectState extends State<Appliedproject> {
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
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('-----Error Fetching Projects: ${snapshot.error}');
                  return Center(child: Text("Error"));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No projects added yet.",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                } else {
                  var projects = snapshot.data!.docs;

                  // Manually filter projects where the user has applied
                  var filteredProjects = projects.where((project) {
                    List<dynamic> appliedIndividuals =
                        project['appliedIndividuals'] ?? [];
                    return appliedIndividuals
                        .any((applicant) => applicant['name'] == currentName);
                  }).toList();

                  // If no projects found
                  if (filteredProjects.isEmpty) {
                    return Center(
                      child: Text(
                        "No projects applied by you.",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        var project = filteredProjects[index];

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
                        String status = project['status'];
                        List<dynamic> appliedIndividuals =
                            project['appliedIndividuals'] ?? [];
                        bool hasUserApplied = appliedIndividuals.any(
                            (applicant) => applicant['name'] == currentName);

                        if (!hasUserApplied) {
                          return SizedBox
                              .shrink(); // Skip this project if the user has already applied
                        }

                        int appliedCount = appliedIndividuals.length;

                        return Padding(
                          padding: EdgeInsets.all(7),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailsScreen(
                                    projectId: projectId,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: isExpanded
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      maxLines: isExpanded ? null : 5,
                                      softWrap: true,
                                    ),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Deadline : $deadline",
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 255, 19, 19),
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "Description",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    DescriptionWidget(description: description),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Applied By : ",
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 144, 143, 143),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          '$appliedCount',
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 0, 0, 0),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Icon(
                                          Icons.person,
                                          color: Colors.deepPurple,
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Budget : ",
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 0, 0, 0),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 106, 0, 148),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Text("Preferences",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 4.0, // Space between each item
                                      runSpacing:
                                          4.0, // Space between lines when wrapping
                                      children: preferences.map((preference) {
                                        return Chip(
                                          label: Text(
                                            preference,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          padding: EdgeInsets.all(2),
                                          backgroundColor: Colors.deepPurple
                                              .shade100, // Optional: Change color
                                        );
                                      }).toList(),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 100,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                255, 69, 0, 180), // Dark Purple
                                            borderRadius: BorderRadius.circular(
                                                10), // Apply border radius
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Text(
                                              hasUserApplied
                                                  ? "Applied"
                                                  : "Apply Now",
                                              style: TextStyle(
                                                color: Colors
                                                    .white, // Set the text color to white
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      project['createdAt'] != null &&
                                              project['createdAt'] is Timestamp
                                          ? 'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((project['createdAt'] as Timestamp).toDate())}'
                                          : 'Posted on: N/A', // Handle null values gracefully
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: const Color.fromARGB(
                                              255, 139, 139, 139)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                }
              })
        ],
      ),
    );
  }
}
