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
  Set<String> dismissedProjectIds = {};

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

                  // Filter projects where the user has applied (individually or as a team)
                  var filteredProjects = projects.where((project) {
                    List<dynamic> appliedIndividuals =
                        project['appliedIndividuals'] ?? [];
                    List<dynamic> appliedTeams = project['appliedTeams'] ?? [];

                    bool hasAppliedIndividually = appliedIndividuals
                        .any((applicant) => applicant['name'] == currentName);

                    bool hasAppliedAsTeam = appliedTeams.any((team) {
                      List<dynamic> members = team['members'] ?? [];
                      return members
                          .any((member) => member['fullName'] == currentName);
                    });

                    bool hasApplied =
                        hasAppliedIndividually || hasAppliedAsTeam;

                    String projectId = project['projectId'] ?? '';
                    return hasApplied &&
                        !dismissedProjectIds.contains(projectId);
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
                        double budget = project['budget'] ?? 0.0;
                        String deadline = project['deadline'] ?? '';
                        String projectId = project['projectId'] ?? '';
                        String status = project['status'];
                        List<dynamic> appliedIndividuals =
                            project['appliedIndividuals'] ?? [];
                        List<dynamic> appliedTeams =
                            project['appliedTeams'] ?? [];

                        bool hasUserApplied = appliedIndividuals.any(
                                (applicant) =>
                                    applicant['name'] == currentName) ||
                            appliedTeams.any((team) {
                              List<dynamic> members = team['members'] ?? [];
                              return members.any((member) =>
                                  member['fullName'] == currentName);
                            });

                        String? appointedFreelancer =
                            project['appointedFreelancer'];
                        String? appointedTeamId = project['appointedTeamId'];

                        // Skip this project if the user has not applied
                        if (!hasUserApplied) {
                          return SizedBox.shrink();
                        }

                        int appliedTeamCount =
                            appliedTeams.fold(0, (sum, team) {
                          List<dynamic> members = team['members'] ?? [];
                          return sum + members.length;
                        });
                        int appliedCount =
                            appliedIndividuals.length + appliedTeamCount;

                        // Determine the button label based on the project status
                        String buttonLabel = determineButtonLabel(
                          appliedIndividuals,
                          appliedTeams,
                          currentName,
                          appointedFreelancer,
                          appointedTeamId,
                        );

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
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Deadline : $deadline",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 13),
                                        ),
                                        SizedBox(width: 10),
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
                                    DescriptionWidget(description: description),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "Applied By : ",
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
                                            color: Colors.deepPurple)
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Budget : ",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                          style: TextStyle(
                                              color: Colors.deepPurple,
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
                                      children: preferences.map((preference) {
                                        return Chip(
                                          label: Text(
                                            preference,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          padding: EdgeInsets.all(2),
                                          backgroundColor:
                                              Colors.deepPurple.shade100,
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
                                            color: Colors.deepPurple,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Text(
                                              buttonLabel,
                                              style: TextStyle(
                                                color: Colors.white,
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
                }
              })
        ],
      ),
    );
  }

  String determineButtonLabel(
    List<dynamic> appliedIndividuals,
    List<dynamic> appliedTeams,
    String currentName,
    String? appointedFreelancer,
    String? appointedTeamId,
  ) {
    bool hasUserAppliedIndividually =
        appliedIndividuals.any((applicant) => applicant['name'] == currentName);
    bool isUserPartOfTeam = appliedTeams.any((team) {
      List<dynamic> members = team['members'] ?? [];
      return members.any((member) => member['fullName'] == currentName);
    });

    // Check if the user is appointed as a freelancer or in a team
    bool isUserAppointedFreelancer = appointedFreelancer == currentName;
    bool isUserAppointedTeam = appointedTeamId != null && isUserPartOfTeam;

    // If the user is appointed as a freelancer or part of a team, return "Appointed"
    if (isUserAppointedFreelancer || isUserAppointedTeam) {
      return "Appointed";
    }
    // If the user has applied but no one has been appointed, return "On-Hold"
    else if ((hasUserAppliedIndividually || isUserPartOfTeam) &&
        (appointedFreelancer == null && appointedTeamId == null)) {
      return "On-Hold"; // User has applied but no one is appointed
    }
    // Otherwise, the user hasn't applied or was rejected after an appointment, show "Rejected"
    else {
      return "Rejected";
    }
  }
}
