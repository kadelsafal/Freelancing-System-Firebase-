import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/description.dart';
import 'package:freelance_system/freelancer/Details/detail.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Recommend extends StatefulWidget {
  const Recommend({super.key});

  @override
  State<Recommend> createState() => _RecommendState();
}

class _RecommendState extends State<Recommend> {
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

  // Fetch resume entities from Firestore
  Future<Map<String, List<String>>> _getResumeEntities() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic> resumeEntities = userDoc['resume_entities'] ?? {};

    // Return the resume entities map
    return resumeEntities
        .map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', isEqualTo: 'New') // Adjust status as needed
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Error Fetching Projects: ${snapshot.error}');
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
                  return FutureBuilder<Map<String, List<String>>>(
                    // Get resume data
                    future: _getResumeEntities(),
                    builder: (context, entitiesSnapshot) {
                      if (entitiesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (entitiesSnapshot.hasError) {
                        return Center(child: Text("Error loading resume data"));
                      }

                      var resumeEntities = entitiesSnapshot.data ?? {};
                      var projects = snapshot.data!.docs;

                      var filteredProjects = projects.where((project) {
                        List<String> projectPreferences =
                            List<String>.from(project['preferences'] ?? []);
                        List<String> userSkills =
                            resumeEntities['SKILLS'] ?? [];
                        List<String> workedAs =
                            resumeEntities['WORKED AS'] ?? [];
                        String projectDescription =
                            project['description'] ?? '';

                        // Convert preferences, skills, and workedAs to lowercase
                        projectPreferences = projectPreferences
                            .map((preference) => preference.toLowerCase())
                            .toList();
                        userSkills = userSkills
                            .map((skill) => skill.toLowerCase())
                            .toList();
                        workedAs =
                            workedAs.map((role) => role.toLowerCase()).toList();
                        projectDescription = projectDescription
                            .toLowerCase(); // Ensure lowercase for description

                        // Check if any preferences match either skills or worked as
                        bool hasMatchingSkills = userSkills
                            .any((skill) => projectPreferences.contains(skill));
                        bool hasMatchingPreferences = workedAs
                            .any((role) => projectPreferences.contains(role));
                        bool hasMatchingDescription =
                            projectDescription.split(' ').any((word) {
                          return userSkills.contains(word) ||
                              workedAs.contains(word);
                        });

                        return hasMatchingSkills ||
                            hasMatchingPreferences ||
                            hasMatchingDescription;
                      }).toList();

                      if (filteredProjects.isEmpty) {
                        return Center(
                          child: Text(
                            "No matching projects found.",
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
                            List<String> preferences = List<String>.from(
                                project['preferences'] ?? ['None']);

                            String title = project['title'] ?? '';
                            String description = project['description'] ?? '';
                            double budget = project['budget'] ?? 0;
                            String deadline = project['deadline'] ?? '';
                            String projectId = project['projectId'] ?? '';
                            String status = project['status'];
                            List<dynamic> appliedIndividuals =
                                project['appliedIndividuals'] ?? [];
                            bool hasUserApplied = appliedIndividuals.any(
                                (applicant) =>
                                    applicant['name'] == currentName);

                            if (hasUserApplied) {
                              return SizedBox
                                  .shrink(); // Skip if user has already applied
                            }

                            int appliedCount = appliedIndividuals.length;

                            return Padding(
                              padding: EdgeInsets.all(7),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProjectDetailsScreen(
                                              projectId: projectId),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: isExpanded
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                          maxLines: isExpanded ? null : 5,
                                          softWrap: true,
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Deadline: $deadline",
                                              style: TextStyle(
                                                  color: Colors.red,
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
                                        SizedBox(height: 4),
                                        DescriptionWidget(
                                            description: description),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "Applied By: ",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '$appliedCount',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Icon(Icons.person,
                                                color: Colors.blue),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "Budget: ",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                              style: TextStyle(
                                                  color: Colors.blue,
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
                                          spacing: 4.0,
                                          runSpacing: 4.0,
                                          children:
                                              preferences.map((preference) {
                                            return Chip(
                                              label: Text(
                                                preference,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              padding: EdgeInsets.all(2),
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                            );
                                          }).toList(),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 100,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                  "Apply",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          project['createdAt'] != null &&
                                                  project['createdAt']
                                                      is Timestamp
                                              ? 'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((project['createdAt'] as Timestamp).toDate())}'
                                              : 'Posted on: N/A',
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                    },
                  );
                }
              })
        ],
      ),
    );
  }
}
