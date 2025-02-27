import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import './description.dart';
import './edit_project.dart';
import 'dart:core'; // Core Duration from Dart
import 'package:googleapis/compute/v1.dart' as compute;

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
                      List<dynamic> appliedIndividuals =
                          project['appliedIndividuals'] ?? [];
                      int appliedCount = appliedIndividuals.length;

                      bool isCompleted = status == "Completed";
                      bool isPending = status == "Pending";
                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          color: isCompleted || isPending
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 220,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                color: isCompleted || isPending
                                                    ? Colors.deepPurple
                                                    : Colors.deepPurple[900],
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: isExpanded
                                                  ? TextOverflow.visible
                                                  : TextOverflow.ellipsis,
                                              maxLines: isExpanded ? null : 5,
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProject(
                                                              projectId:
                                                                  projectId)));
                                            },
                                            icon: Icon(
                                              Icons.edit_note_outlined,
                                              color: isCompleted || isPending
                                                  ? Colors.deepPurple
                                                  : Colors.deepPurple,
                                              size: 40,
                                            )),
                                        SizedBox(width: 0),
                                        IconButton(
                                          onPressed: () async {
                                            bool confirmDelete =
                                                await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text("Confirm Delete"),
                                                  content: Text(
                                                      "Are you sure you want to delete this project?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(
                                                            false); // No, don't delete
                                                      },
                                                      child: Text("No",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(
                                                            true); // Yes, delete
                                                      },
                                                      child: Text("Yes",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
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
                                          icon: Icon(
                                            Icons.delete_forever,
                                            color: const Color.fromARGB(
                                                255, 255, 3, 3),
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                SizedBox(height: 15),
                                if (!isCompleted) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Deadline : $deadline",
                                            style: TextStyle(
                                                color: isPending
                                                    ? const Color.fromARGB(
                                                        255, 255, 19, 19)
                                                    : Colors.red,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "Description",
                                        style: TextStyle(
                                            color: isPending
                                                ? Colors.deepPurple
                                                : const Color.fromARGB(
                                                    255, 0, 0, 0),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      DescriptionWidget(
                                          description: description),
                                      if (!isPending) ...[
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Applied By : ",
                                              style: TextStyle(
                                                  color: const Color.fromARGB(
                                                      255, 144, 143, 143),
                                                  fontSize: 13,
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
                                      ],
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(right: 10),
                                              child: isPending
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          "Budget : ",
                                                          style: TextStyle(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255, 0, 0, 0),
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .deepPurple,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    )
                                                  : // If not in Pending Status
                                                  Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          "Budget : ",
                                                          style: TextStyle(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255, 0, 0, 0),
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        Text(
                                                          "${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                                                          style: TextStyle(
                                                              color: const Color
                                                                  .fromARGB(255,
                                                                  106, 0, 148),
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    )),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      if (!isPending) ...[
                                        Text("Preferences",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(height: 5),
                                        Wrap(
                                          spacing:
                                              4.0, // Space between each item
                                          runSpacing:
                                              4.0, // Space between lines when wrapping
                                          children:
                                              preferences.map((preference) {
                                            return Chip(
                                              label: Text(
                                                preference,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              padding: EdgeInsets.all(2),
                                              backgroundColor: Colors.deepPurple
                                                  .shade100, // Optional: Change color
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      SizedBox(height: 10),
                                    ],
                                  )
                                ],
                                Text(
                                  project['createdAt'] != null &&
                                          project['createdAt'] is Timestamp
                                      ? 'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((project['createdAt'] as Timestamp).toDate())}'
                                      : 'Posted on: N/A', // Handle null values gracefully
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isCompleted || isPending
                                          ? const Color.fromARGB(
                                              255, 80, 80, 80)
                                          : const Color.fromARGB(
                                              255, 139, 139, 139)),
                                ),
                                if (isCompleted) // Show checkmark when completed
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Completed  ",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.deepPurple,
                                          size: 25,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (isPending) // Show checkmark when completed
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Pending ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            color: const Color.fromARGB(
                                                255, 0, 0, 0),
                                          ),
                                        ),
                                        Icon(
                                          Icons.pending_actions,
                                          color: Colors.deepPurple,
                                          size: 25,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              })
        ],
      ),
    );
  }
}
