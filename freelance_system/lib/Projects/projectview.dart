import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/allapplicants_tab/allapplicants.dart';

import 'package:freelance_system/Projects/appointeduser/appointeduserui.dart';

import 'package:freelance_system/Projects/recommendtab.dart';
import 'package:freelance_system/Projects/teams/teamsTab.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.white,
      ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1976D2).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.attach_money,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Budget: \$${project['budget']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Deadline: ${project['deadline'] ?? 'No deadline'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.people,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Applications: ${(project['appliedIndividuals']?.length ?? 0) + (project['appliedTeams']?.length ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1976D2).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                project['description'] ?? 'No description',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1976D2).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Skills/Preferences',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (project['preferences']
                                            as List<dynamic>? ??
                                        [])
                                    .map((preference) => Container(
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
                                            preference.toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF1976D2),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status != 'Pending' && status != 'Completed') ...[
                    SizedBox(
                      height: 50,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1976D2),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF1976D2),
                        indicatorWeight: 3,
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
                            TeamsTab(
                                appliedTeams: appliedTeams,
                                projectId: widget.projectId),
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
                              backgroundColor: const Color(0xFF1976D2),
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
