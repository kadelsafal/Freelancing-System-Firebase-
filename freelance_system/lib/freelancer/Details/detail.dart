import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/freelancer/Details/applysheet.dart';
import 'package:freelance_system/freelancer/Details/applyteam.dart';
import 'package:freelance_system/freelancer/Details/appointedfreelancer.dart';
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
  String applicationStatus = "none";
  Future<bool>?
      isUserInAppointedTeamFuture; // Added a Future variable for the appointed team check

  String _getWrappedTitle(String text, int wordsPerLine) {
    List<String> words = text.split(' ');
    List<String> wrappedLines = [];

    for (int i = 0; i < words.length; i += wordsPerLine) {
      wrappedLines.add(words
          .sublist(i,
              i + wordsPerLine > words.length ? words.length : i + wordsPerLine)
          .join(' '));
    }

    return wrappedLines.join('\n');
  }

  Future<bool> isUserInAppointedTeam(
      String appointedTeamId, String currentUserId) async {
    try {
      var teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(appointedTeamId)
          .get();

      if (teamDoc.exists) {
        List<dynamic> members = teamDoc['members'] ?? [];
        for (var member in members) {
          if (member is Map<String, dynamic> &&
              member['userId'] == currentUserId) {
            return true; // User is a member of the appointed team
          }
        }
      }
    } catch (e) {
      print("Error fetching team members: $e");
    }
    return false; // User is not in the appointed team
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context, listen: false);
    String currentName = userProvider.userName;
    String currentuserId = userProvider.userId;

    return Scaffold(
      appBar: AppBar(title: Text("Project Details")),
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
            if (preferences.isEmpty) preferences = ["None"];

            String title = project['title'] ?? '';
            String description = project['description'] ?? '';
            double budget = project['budget'] ?? 0;
            String deadline = project['deadline'] ?? '';
            String projectId = project['projectId'] ?? '';
            List<dynamic> appliedIndividuals =
                project['appliedIndividuals'] ?? [];
            int appliedCount = appliedIndividuals.length;

            String appointedFreelancer = project['appointedFreelancer'] ?? '';
            applicationStatus = "none"; // Reset

            // Check if applied as a team
            List<dynamic> appliedTeams = project['appliedTeams'] ?? [];
            for (var team in appliedTeams) {
              if (team != null && team is Map<String, dynamic>) {
                List<dynamic> members = team['members'] ?? [];
                bool isInTeam = members.any((member) =>
                    member is Map<String, dynamic> &&
                    member['userId'] == currentuserId);
                if (isInTeam) {
                  applicationStatus = "applied_team";
                  // Now check if this team is appointed
                  if (project['appointedTeamId'] == team['teamId']) {
                    // Team is appointed, so display AppointedFreelancerMessage
                    applicationStatus = "team_appointed";
                  }
                  break;
                }
              }
            }

            // Check if applied solo (after checking team and appointed)
            for (var applicant in appliedIndividuals) {
              if (applicant != null && applicant is Map<String, dynamic>) {
                if (applicant.containsKey('name') &&
                    applicant['name'] == currentName &&
                    !applicant.containsKey('teamMembers')) {
                  applicationStatus = "applied_solo";
                  break;
                }
              }
            }
            // Check if appointed as freelancer first
            if (appointedFreelancer == currentName) {
              applicationStatus =
                  "appointed"; // User is appointed as freelancer
            } else if (project['appointedTeamId'] != null) {
              // Check if the user is in the appointed team
              isUserInAppointedTeamFuture = isUserInAppointedTeam(
                  project['appointedTeamId'],
                  currentuserId); // Save future for FutureBuilder
            }

            print("Application Status: $applicationStatus");
            // Determine button text and state
            String buttonText;
            bool isButtonDisabled;

            switch (applicationStatus) {
              case "appointed":
                buttonText = "Appointed";
                isButtonDisabled = true;
                break;
              case "rejected":
                buttonText = "Rejected";
                isButtonDisabled = true;
                break;
              case "applied_solo":
                buttonText = "Applied Solo";
                isButtonDisabled = true;
                break;
              case "applied_team":
                buttonText = "Applied as Team";
                isButtonDisabled = true;
                break;
              case "team_appointed":
                buttonText = "Appointed as Team Member";
                isButtonDisabled = true;
                break;
              case "none":
              default:
                buttonText = "Apply Now";
                isButtonDisabled = false;
                break;
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your existing UI code...
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
                          : 'Posted on: N/A',
                      style: TextStyle(
                          fontSize: 12, color: Color.fromARGB(255, 78, 78, 78)),
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
                        color: Color.fromARGB(255, 250, 231, 254),
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
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                          style: TextStyle(
                              color: Color.fromARGB(255, 106, 0, 148),
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Deadline : $deadline",
                      style: TextStyle(
                          color: Color.fromARGB(255, 201, 0, 0), fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Applied By : ",
                          style: TextStyle(
                              color: Color.fromARGB(255, 130, 130, 130),
                              fontSize: 13,
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
                        Icon(Icons.person, color: Colors.deepPurple)
                      ],
                    ),
                    SizedBox(height: 14),
                    Text("Preferences",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: preferences.map((preference) {
                        return Chip(
                          label: Text(
                            preference,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          padding: EdgeInsets.all(4),
                          backgroundColor: Colors.deepPurple.shade100,
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 14),
                    Center(
                      child: ElevatedButton(
                        onPressed: isButtonDisabled
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (BuildContext context) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Choose how to apply",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // Close the bottom sheet
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder:
                                                    (BuildContext context) {
                                                  return ApplyModalSheet(
                                                      projectId: projectId);
                                                },
                                              );
                                            },
                                            icon: Icon(Icons.person),
                                            label: Text("Apply Solo"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurple,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  Size(double.infinity, 45),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // Close the bottom sheet
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                builder:
                                                    (BuildContext context) {
                                                  return ApplyWithTeamModalSheet(
                                                      projectId: projectId);
                                                },
                                              );
                                            },
                                            icon: Icon(Icons.group),
                                            label: Text("Apply with Team"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurple.shade100,
                                              foregroundColor:
                                                  Colors.deepPurple,
                                              minimumSize:
                                                  Size(double.infinity, 45),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                        child: Text(buttonText),
                      ),
                    ),

                    if (applicationStatus == "appointed" ||
                        applicationStatus == "team_appointed")
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 800),
                        child: AppointedFreelancerMessage(
                          projectId: projectId,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
