import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/admin/ProjectDetailScreen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _deleteProject(String projectId) async {
    if (!_mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();

      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting project: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    tooltip: 'Back',
                    onPressed: () {
                      if (!_mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.work, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Project Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('projects').snapshots(),
        builder: (context, projectSnapshot) {
          if (!_mounted) return const SizedBox.shrink();

          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (projectSnapshot.hasError) {
            return const Center(child: Text('Error fetching projects.'));
          }

          if (!projectSnapshot.hasData || projectSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No projects found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final projectDocs = projectSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (!_mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailScreen(projectDoc: projectDoc),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor(data['status'])
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        statusIcon(data['status']),
                                        color: statusColor(data['status']),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        (data['status'] ?? 'Pending')
                                            .toString(),
                                        style: TextStyle(
                                          color: statusColor(data['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    if (!_mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        title: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.red.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Delete Project',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete this project? This action cannot be undone.',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey[600],
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await _deleteProject(projectId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if ((data['description'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Text(
                                data['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 15),
                              ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  icon: Icons.currency_rupee,
                                  label: 'Budget: ${data['budget'] ?? 'N/A'}',
                                  color: Colors.green,
                                ),
                                _buildInfoChip(
                                  icon: Icons.calendar_today,
                                  label: 'Deadline: $deadline',
                                  color: Colors.red,
                                ),
                                _buildInfoChip(
                                  icon: Icons.people,
                                  label: 'Applicants: $totalApplicants',
                                  color: Colors.purple,
                                ),
                                _buildInfoChip(
                                  icon: Icons.person,
                                  label: 'Posted By: $postedBy',
                                  color: Colors.teal,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: (appointedFreelancer != null ||
                                        appointedTeam != null)
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    appointedFreelancer != null
                                        ? Icons.person
                                        : appointedTeam != null
                                            ? Icons.groups
                                            : Icons.hourglass_empty,
                                    color: (appointedFreelancer != null ||
                                            appointedTeam != null)
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appointedFreelancer != null
                                        ? 'Appointed Freelancer: $appointedFreelancer'
                                        : appointedTeam != null
                                            ? 'Appointed Team: $appointedTeam'
                                            : 'Not Appointed Yet',
                                    style: TextStyle(
                                      color: (appointedFreelancer != null ||
                                              appointedTeam != null)
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(dynamic status) {
  switch ((status ?? '').toString().toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'cancelled':
      return Colors.red;
    case 'active':
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

IconData statusIcon(dynamic status) {
  switch ((status ?? '').toString().toLowerCase()) {
    case 'completed':
      return Icons.check_circle_outline;
    case 'pending':
      return Icons.hourglass_empty;
    case 'cancelled':
      return Icons.cancel_outlined;
    case 'active':
      return Icons.play_circle_outline;
    default:
      return Icons.info_outline;
  }
}
