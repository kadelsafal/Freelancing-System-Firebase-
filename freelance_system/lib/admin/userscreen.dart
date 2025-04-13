import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> _deleteUser(String userId) async {
    try {
      final projectSnapshot = await db
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in projectSnapshot.docs) {
        await doc.reference.delete();
      }

      await db.collection('users').doc(userId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting user')),
      );
    }
  }

  Stream<int> _projectCountStream(String userId) {
    return db
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _toggleUserStatus(String userId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    await db.collection('users').doc(userId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching users.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userId = userDoc.id;
              final userData = userDoc.data() as Map<String, dynamic>;

              final String userName = userData['Full Name'] ?? 'No Name';
              final String email = userData['email'] ?? 'N/A';
              final String role = userData['role'] ?? 'User';
              final String status = userData['status'] ?? 'active';
              final Timestamp createdAtTS =
                  userData['createdAt'] ?? Timestamp.now();
              final String createdAt =
                  DateFormat.yMMMd().format(createdAtTS.toDate());

              final String firstLetter =
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?';

              return StreamBuilder<int>(
                stream: _projectCountStream(userId),
                builder: (context, projectSnapshot) {
                  final int projectCount = projectSnapshot.data ?? 0;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    Text(email,
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text("Role: $role"),
                                    Text("Created: $createdAt"),
                                    Text("Projects: $projectCount"),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: status == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: const Text("Projects"),
                                onPressed: () {
                                  // TODO: Navigate to project list screen
                                },
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: Icon(status == 'active'
                                    ? Icons.block
                                    : Icons.check_circle),
                                label: Text(status == 'active'
                                    ? 'Suspend'
                                    : 'Activate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: status == 'active'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                onPressed: () =>
                                    _toggleUserStatus(userId, status),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text("Delete"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete User'),
                                      content: const Text(
                                          'Are you sure you want to delete this user and all their projects?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteUser(userId);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
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
