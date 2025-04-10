import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/applicantstab.dart';
import 'package:freelance_system/Projects/appointed_freelancer.dart';
import 'package:freelance_system/Projects/TeamsTab.dart';
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
  bool _freelancerRemoved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ Safe
    super.dispose();
  }

  void onAppointmentRemoved() {
    setState(() {
      _freelancerRemoved = true;
    });
  }

// Function to mark the project as completed
  void markProjectAsCompleted() async {
    try {
      // Fetch the current project status
      var projectSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      String currentStatus = projectSnapshot['status'];

      // Only update the status to "Completed" if it's not already "Completed"
      if (currentStatus != "Completed") {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({'status': 'Completed'});

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project marked as completed')),
        );
      } else {
        // If already "Completed", show a message indicating it's already done
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project is already completed')),
        );
      }
    } catch (e) {
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking project as completed: $e')),
      );
    }
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
            List<dynamic> appliedTeams = project['appliedTeams'] ?? [];
            List<dynamic> freshers =
                applicants.where((a) => a['experience'] == 'Fresher').toList();
            List<dynamic> recommended =
                applicants.where((a) => a['recommended'] == true).toList();
            String appointFreelancer = project['appointedFreelancer'] ?? '';
            String appointTeam = project['appointedTeam'] ?? '';

            String title = project['title'] ?? '';
            String description = project['description'] ?? '';
            double budget = project['budget'] ?? 0;
            String deadline = project['deadline'] ?? '';
            int appliedCount =
                applicants.length + appliedTeams.length; // Combined count
            String status = project['status'] ?? 'Pending';

            // Reset _freelancerRemoved if a new freelancer or team is appointed
            if (appointFreelancer.isNotEmpty || appointTeam.isNotEmpty) {
              if (_freelancerRemoved) {
                _freelancerRemoved = false;
              }
            }
            // Only change status to "Pending" if not already "Completed"
            if ((appointFreelancer.isNotEmpty || appointTeam.isNotEmpty) &&
                status != "Completed") {
              if (status != "Pending") {
                FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .update({'status': 'Pending'}).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Project status updated to Pending.")),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating status: $error")),
                  );
                });
              }
            }
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
                  if (status != 'Pending' && status != 'Completed') ...[
                    SizedBox(
                      height: 50,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.grey,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        isScrollable: false,
                        tabs: const [
                          Tab(text: "All Applicants"),
                          Tab(text: "Recommend"),
                          Tab(text: "Teams"),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 150,
                      ),
                      child: SizedBox(
                        height: 450,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            AllApplicants(
                              projectId: widget.projectId,
                              applicants: project['appliedIndividuals'] ?? [],
                              appliedTeams: project['appliedTeams'] ?? [],
                              appointedFreelancer:
                                  project['appointedFreelancer'] ?? '',
                              appointedTeam: project['appointedTeam'] ?? '',
                              appointedTeamId: project['appointedTeamId'] ?? '',
                              appointedFreelancerId:
                                  project['appointedFreelancerId'] ?? '',
                            ),
                            Recommended(
                              // If needed, pass individual recommendations here
                              // Applied teams
                              projectId: widget.projectId,
                              projectSkills: List<String>.from(
                                  project['preferences'] ??
                                      []), // Ensure this is a List<String>
                              applicants: project['appliedIndividuals'] ??
                                  [], // Applied individuals
                            ),
                            Teamstab(
                                projectId: widget.projectId,
                                appliedTeams: project['appliedTeams'] ?? []),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if ((appointFreelancer.isNotEmpty ||
                          appointTeam.isNotEmpty) &&
                      !_freelancerRemoved) ...[
                    const Divider(
                      thickness: 1.5,
                      color: Colors.grey,
                      height: 40,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppointedUser(
                        appointedName: appointFreelancer.isNotEmpty
                            ? appointFreelancer
                            : appointTeam,
                        appointedType: appointFreelancer.isNotEmpty
                            ? 'Freelancer'
                            : 'Team',
                        projectId: widget.projectId,
                        onAppointedUserRemoved: () {
                          setState(() {
                            _freelancerRemoved = true;
                          });
                        },
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        width: 280,
                        height: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: markProjectAsCompleted,
                            child: const Text('Complete Project '),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
