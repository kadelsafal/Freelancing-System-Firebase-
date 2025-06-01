import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/projectview.dart';
import 'package:intl/intl.dart';
import './description.dart';
import './edit_project.dart';
import 'dart:core'; // Core Duration from Dart

class Projectpost extends StatefulWidget {
  final String userId;
  const Projectpost({super.key, required this.userId});

  @override
  State<Projectpost> createState() => _ProjectpostState();
}

class _ProjectpostState extends State<Projectpost> {
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
    return Padding(
      padding: EdgeInsets.all(9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('userId', isEqualTo: widget.userId)
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
                      String appointFreelancer =
                          project['appointedFreelancer'] ?? '';
                      String appointTeam = project['appointedTeam'] ?? '';
                      List<dynamic> appliedIndividuals =
                          project['appliedIndividuals'] ?? [];
                      List<dynamic> appliedTeams =
                          project['appliedTeams'] ?? [];
                      int appliedCount =
                          appliedIndividuals.length + appliedTeams.length;

                      String appoint = appointFreelancer.isNotEmpty
                          ? appointFreelancer
                          : appointTeam;

                      bool isFreelancerAppointed = appointFreelancer.isNotEmpty;
                      bool isTeamAppointed = appointTeam.isNotEmpty;

                      bool isCompleted = status == "Completed";
                      bool isPending = status == "Pending";

                      // Check if Freelancer or Team is appointed and update status to "Pending"
                      // Check if Freelancer or Team is appointed and update status to "Pending"

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Projectview(
                                  projectId: projectId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1976D2).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isPending
                                    ? Colors.amber.withOpacity(0.3)
                                    : isCompleted
                                        ? Colors.green.withOpacity(0.3)
                                        : const Color(0xFF1976D2)
                                            .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
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
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditProject(
                                                    projectId: projectId,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1976D2)
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.edit_outlined,
                                                color: Color(0xFF1976D2),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              bool confirmDelete =
                                                  await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    title: const Text(
                                                      "Delete Project",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF1976D2),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    content: const Text(
                                                      "Are you sure you want to delete this project?",
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(false);
                                                        },
                                                        child: const Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(true);
                                                        },
                                                        child: const Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              if (confirmDelete == true) {
                                                await FirebaseFirestore.instance
                                                    .collection("projects")
                                                    .doc(project.id)
                                                    .delete();
                                              }
                                            },
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (!isCompleted) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPending
                                            ? Colors.amber.withOpacity(0.1)
                                            : const Color(0xFF1976D2)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isPending
                                              ? Colors.amber[800]
                                              : const Color(0xFF1976D2),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.currency_rupee,
                                              color: Color(0xFF1976D2),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Budget: Rs ${budget.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFF1976D2),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFF1976D2),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Deadline: $deadline',
                                              style: const TextStyle(
                                                color: Color(0xFF1976D2),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.people,
                                              color: Color(0xFF1976D2),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Applications: $appliedCount',
                                              style: const TextStyle(
                                                color: Color(0xFF1976D2),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: preferences.map((preference) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1976D2)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          preference,
                                          style: const TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF1976D2)
                                            .withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1976D2)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: appoint.isNotEmpty
                                              ? FutureBuilder<DocumentSnapshot>(
                                                  future: isFreelancerAppointed
                                                      ? FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(
                                                              appointFreelancer)
                                                          .get()
                                                      : null,
                                                  builder: (context, snapshot) {
                                                    if (isFreelancerAppointed &&
                                                        snapshot.hasData) {
                                                      final userData =
                                                          snapshot.data!.data()
                                                              as Map<String,
                                                                  dynamic>?;
                                                      final profileImage =
                                                          userData?[
                                                              'profileImage'];

                                                      return CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            const Color(
                                                                    0xFF1976D2)
                                                                .withOpacity(
                                                                    0.1),
                                                        backgroundImage:
                                                            profileImage !=
                                                                        null &&
                                                                    profileImage
                                                                        .isNotEmpty
                                                                ? NetworkImage(
                                                                    profileImage)
                                                                : null,
                                                        child: profileImage ==
                                                                    null ||
                                                                profileImage
                                                                    .isEmpty
                                                            ? Text(
                                                                appoint[0]
                                                                    .toUpperCase(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Color(
                                                                      0xFF1976D2),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              )
                                                            : null,
                                                      );
                                                    } else {
                                                      return CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            const Color(
                                                                    0xFF1976D2)
                                                                .withOpacity(
                                                                    0.1),
                                                        child: Text(
                                                          appoint[0]
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF1976D2),
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              : Icon(
                                                  isFreelancerAppointed
                                                      ? Icons.person
                                                      : isTeamAppointed
                                                          ? Icons.group
                                                          : Icons.person_off,
                                                  color:
                                                      const Color(0xFF1976D2),
                                                  size: 20,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isFreelancerAppointed
                                                    ? "Appointed Freelancer"
                                                    : isTeamAppointed
                                                        ? "Appointed Team"
                                                        : "Not Appointed",
                                                style: const TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (appoint.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  appoint,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
          SizedBox(
            height: 60,
          )
        ],
      ),
    );
  }
}
