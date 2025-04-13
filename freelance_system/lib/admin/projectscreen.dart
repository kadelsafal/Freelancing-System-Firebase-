import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Project Management')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('projects').snapshots(),
        builder: (context, projectSnapshot) {
          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (projectSnapshot.hasError) {
            return const Center(child: Text('Error fetching projects.'));
          }

          if (!projectSnapshot.hasData || projectSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No projects found.'));
          }

          final projectDocs = projectSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: projectDocs.length,
            itemBuilder: (context, index) {
              final projectDoc = projectDocs[index];
              final data = projectDoc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No Title';
              final deadline = data['deadline'] ?? 'N/A';
              final userId = data['userId'];
              final appliedIndividuals =
                  data['appliedIndividuals'] as List? ?? [];
              final appliedTeams = data['appliedTeams'] as List? ?? [];

              final totalApplicants =
                  appliedIndividuals.length + appliedTeams.length;

              final appointedFreelancer = data['appointedFreelancer'];
              final appointedTeam = data['appointedTeam'];
              final projectId = projectDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: db.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  String postedBy = 'Unknown';

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    postedBy = userData['Full Name'] ?? 'Unknown';
                  }

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Project'),
                                      content: const Text(
                                          'Are you sure you want to delete this project?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await db
                                                .collection('projects')
                                                .doc(projectId)
                                                .delete();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Project deleted')),
                                            );
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text("Deadline: $deadline"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16),
                              const SizedBox(width: 6),
                              Text("Applicants: $totalApplicants"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.assignment_ind, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  appointedFreelancer != null
                                      ? "Appointed Freelancer: $appointedFreelancer"
                                      : appointedTeam != null
                                          ? "Appointed Team: $appointedTeam"
                                          : "Not Appointed Yet",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 6),
                              Text("Posted By: $postedBy"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
