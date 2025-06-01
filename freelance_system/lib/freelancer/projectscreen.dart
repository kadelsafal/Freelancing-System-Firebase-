import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/description.dart';
import 'package:freelance_system/freelancer/Details/detail.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FreelancerProjectscreen extends StatefulWidget {
  const FreelancerProjectscreen({super.key});

  @override
  State<FreelancerProjectscreen> createState() =>
      _FreelancerProjectscreenState();
}

class _FreelancerProjectscreenState extends State<FreelancerProjectscreen> {
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
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', isEqualTo: 'New')
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
// Filter projects where the user has NOT applied as an individual or in a team
                  var filteredProjects = projects.where((project) {
                    List<dynamic> appliedIndividuals =
                        project['appliedIndividuals'] ?? [];
                    List<dynamic> appliedTeams = project['appliedTeams'] ?? [];

                    bool appliedAsIndividual = appliedIndividuals
                        .any((applicant) => applicant['name'] == currentName);

                    bool appliedAsTeam = appliedTeams.any((team) {
                      List<dynamic> members = team['members'] ?? [];
                      return members
                          .any((member) => member['fullName'] == currentName);
                    });

                    return !appliedAsIndividual && !appliedAsTeam;
                  }).toList();

                  // Check if there are no more projects to display
                  if (filteredProjects.isEmpty) {
                    return Center(
                      child: Text(
                        "No more projects to display.",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        var project = projects[index];
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
                        List<dynamic> appliedTeams =
                            project['appliedTeams'] ?? [];

                        bool hasAppliedIndividually = appliedIndividuals.any(
                            (applicant) => applicant['name'] == currentName);

                        bool hasAppliedAsTeam = appliedTeams.any((team) {
                          List<dynamic> members = team['members'] ?? [];
                          return members.any(
                              (member) => member['fullName'] == currentName);
                        });

                        bool hasUserApplied =
                            hasAppliedIndividually || hasAppliedAsTeam;

                        if (hasUserApplied) {
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
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: isExpanded
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      maxLines: isExpanded ? null : 2,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person,
                                              color: Color(0xFF1976D2),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(project['userId'])
                                                  .get(),
                                              builder: (context, userSnapshot) {
                                                if (userSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text(
                                                    "Posted by: ...",
                                                    style: TextStyle(
                                                      color: Color(0xFF1976D2),
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                } else if (userSnapshot
                                                        .hasError ||
                                                    !userSnapshot.hasData ||
                                                    !userSnapshot
                                                        .data!.exists) {
                                                  return const Text(
                                                    "Posted by: Unknown",
                                                    style: TextStyle(
                                                      color: Color(0xFF1976D2),
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                } else {
                                                  String posterName =
                                                      userSnapshot.data![
                                                              'Full Name'] ??
                                                          'Unknown';
                                                  return Text(
                                                    "Posted by: $posterName",
                                                    style: const TextStyle(
                                                      color: Color(0xFF1976D2),
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1976D2)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "Deadline: $deadline",
                                            style: const TextStyle(
                                              color: Color(0xFF1976D2),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Budget: ",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                          style: const TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Required Skills",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      children: preferences.map((preference) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1976D2)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            preference,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProjectDetailsScreen(
                                                  projectId: projectId,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1976D2),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            "View Details",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
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
