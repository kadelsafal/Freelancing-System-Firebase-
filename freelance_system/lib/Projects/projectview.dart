import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/applicantstab.dart';
import 'package:freelance_system/Projects/freshertab.dart';
import 'package:freelance_system/Projects/recommendtab.dart';
import 'package:intl/intl.dart';

class Projectview extends StatefulWidget {
  final String projectId;
  const Projectview({super.key, required this.projectId});

  @override
  State<Projectview> createState() => _ProjectviewState();
}

class _ProjectviewState extends State<Projectview>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Project not found"));
          } else {
            var project = snapshot.data!;
            List<String> preferences =
                List<String>.from(project['preferences'] ?? ['None']);
            List<dynamic> applicants = project['appliedIndividuals'] ?? [];
            List<dynamic> freshers =
                applicants.where((a) => a['experience'] == 'Fresher').toList();
            List<dynamic> recommended =
                applicants.where((a) => a['recommended'] == true).toList();
            String appoint = project['appointedFreelancer'] ?? '';
            String title = project['title'] ?? '';
            String description = project['description'] ?? '';
            double budget = project['budget'] ?? 0;
            String deadline = project['deadline'] ?? '';
            int appliedCount = applicants.length;
            String status = project['status'] ?? 'Pending'; // Add status check

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          project['createdAt'] != null &&
                                  project['createdAt'] is Timestamp
                              ? 'Posted on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((project['createdAt'] as Timestamp).toDate())}'
                              : 'Posted on: N/A',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 78, 78, 78)),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "Description",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 250, 231, 254),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(description),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Budget: ${NumberFormat("#,##0", "en_US").format(budget)} Rs",
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 106, 0, 148),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Deadline: $deadline",
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 201, 0, 0),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Applied By: ",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 130, 130, 130),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$appliedCount',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Icon(
                              Icons.person,
                              color: Colors.deepPurple,
                            )
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text("Preferences",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4.0,
                          runSpacing: 4.0,
                          children: preferences.map((preference) {
                            return Chip(
                              label: Text(
                                preference,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              padding: const EdgeInsets.all(4),
                              backgroundColor: Colors.deepPurple.shade100,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  // Show TabBar only if the project is neither pending nor completed
                  if (status != 'Pending' && status != 'Completed') ...[
                    SizedBox(
                      height: 50,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.grey,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        isScrollable: false, // Ensures full names fit
                        tabs: const [
                          Tab(text: "All Applicants"),
                          Tab(text: "Recommend"),
                          Tab(text: "Freshers"),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 150,
                      ),
                      child: SizedBox(
                        height: 450, // max height
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            AllApplicants(
                              projectId: widget.projectId,
                              applicants: project['appliedIndividuals'],
                              appointedFreelancer:
                                  project['appointedFreelancer'] ?? '',
                            ),
                            Recommended(recommended: recommended),
                            Freshers(freshers: freshers),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (appoint.isNotEmpty)
                    const Divider(
                      thickness: 1.5,
                      color: Colors.grey,
                      height: 40,
                    ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Appointed Freelancer",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text(
                                appoint.isNotEmpty ? appoint[0] : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              appoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Confirm before removing
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Remove Freelancer"),
                                  content: const Text(
                                      "Are you sure you want to remove the appointed freelancer?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Remove"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm) {
                                // Clear appointed freelancer info
                                await FirebaseFirestore.instance
                                    .collection('projects')
                                    .doc(widget.projectId)
                                    .update({
                                  'appointedFreelancer': '',
                                  'appointedFreelancerID': '',
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Appointed freelancer removed")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Remove Freelancer"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
