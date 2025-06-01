import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_system/admin/coursescreen.dart'; // Import for CourseDetailScreen
import 'package:freelance_system/admin/adminscreen.dart'; // Import for AdminScreen
import 'package:flutter/scheduler.dart'; // Add this import

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Recursive delete all subcollections of a document
  Future<void> _deleteUserCompletely(String userId) async {
    final userDocRef = db.collection('users').doc(userId);

    try {
      // Delete all projects belonging to user
      final projectSnapshot = await db
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in projectSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await userDocRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User and related data deleted successfully')),
      );

      // Note: Firebase Auth deletion should be done securely via backend/cloud function.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
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

  Stream<int> _courseCountStream(String userId) {
    return db
        .collection('courses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _toggleUserStatus(String userId, String? currentStatus) async {
    final newStatus = (currentStatus == 'active' || currentStatus == null)
        ? 'suspended'
        : 'active';
    await db
        .collection('users')
        .doc(userId)
        .set({'status': newStatus}, SetOptions(merge: true));
  }

  Future<void> _showUserProjects(String userId) async {
    final projectSnapshot = await db
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .get();

    final projects = projectSnapshot.docs;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  'User Projects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (projects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No projects found.',
                      style: TextStyle(fontSize: 16)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final data = projects[i].data();
                    final title = data['title'] ?? 'Untitled Project';
                    return ListTile(
                      leading: const Icon(Icons.work, color: Color(0xFF1976D2)),
                      title: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUserCourses(String userId) async {
    final courseSnapshot =
        await db.collection('courses').where('userId', isEqualTo: userId).get();

    final courses = courseSnapshot.docs;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  'User Courses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (courses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      Text('No courses found.', style: TextStyle(fontSize: 16)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (context, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final data = courses[i].data();
                    final title = data['title'] ?? 'Untitled Course';
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined,
                          color: Color(0xFF1976D2)),
                      title: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(context); // Close the modal bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseDetailScreen(courseDoc: courses[i]),
                          ),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'Back to Admin',
                    onPressed: () {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminScreen()),
                        );
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "User Management",
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "All Users",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final userId = userDoc.id;
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final String userName =
                            userData['Full Name'] ?? 'No Name';
                        final String email = userData['email'] ?? 'N/A';
                        final String role = userData['role'] ?? 'User';
                        final String status =
                            (userData['status'] as String?) ?? 'active';
                        final Timestamp createdAtTS =
                            userData['createdAt'] ?? Timestamp.now();
                        final String createdAt =
                            DateFormat.yMMMd().format(createdAtTS.toDate());
                        final String firstLetter = userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?';
                        final String? profileImage =
                            userData['profileImage'] as String?;
                        return StreamBuilder<int>(
                          stream: _projectCountStream(userId),
                          builder: (context, projectSnapshot) {
                            final int projectCount = projectSnapshot.data ?? 0;
                            return StreamBuilder<int>(
                              stream: _courseCountStream(userId),
                              builder: (context, courseSnapshot) {
                                final int courseCount =
                                    courseSnapshot.data ?? 0;
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            profileImage != null &&
                                                    profileImage.isNotEmpty
                                                ? CircleAvatar(
                                                    radius: 28,
                                                    backgroundImage:
                                                        NetworkImage(
                                                            profileImage),
                                                  )
                                                : CircleAvatar(
                                                    radius: 28,
                                                    backgroundColor:
                                                        const Color(0xFF1976D2),
                                                    child: Text(
                                                      firstLetter,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(userName,
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                  Text(email,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey)),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .blue.shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          role,
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF1976D2),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              status == 'active'
                                                                  ? Colors.green
                                                                      .shade50
                                                                  : Colors.red
                                                                      .shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          status.toUpperCase(),
                                                          style: TextStyle(
                                                            color: status ==
                                                                    'active'
                                                                ? Colors.green
                                                                    .shade800
                                                                : Colors.red
                                                                    .shade800,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text("Created: $createdAt",
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.black54)),
                                                  Text(
                                                      "Projects: $projectCount",
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.black54)),
                                                  Text("Courses: $courseCount",
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.black54)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.visibility,
                                                  color: Color(0xFF1976D2)),
                                              label: const Text("Projects",
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF1976D2))),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Color(0xFF1976D2)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () =>
                                                  _showUserProjects(userId),
                                            ),
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.menu_book,
                                                  color: Color(0xFF1976D2)),
                                              label: const Text("Courses",
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF1976D2))),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Color(0xFF1976D2)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () =>
                                                  _showUserCourses(userId),
                                            ),
                                            OutlinedButton.icon(
                                              icon: Icon(
                                                  status == 'active'
                                                      ? Icons.block
                                                      : Icons.check_circle,
                                                  color: status == 'active'
                                                      ? Colors.red
                                                      : Colors.green),
                                              label: Text(
                                                  status == 'active'
                                                      ? 'Suspend'
                                                      : 'Activate',
                                                  style: TextStyle(
                                                      color: status == 'active'
                                                          ? Colors.red
                                                          : Colors.green)),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                    color: status == 'active'
                                                        ? Colors.red
                                                        : Colors.green),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () =>
                                                  _toggleUserStatus(
                                                      userId, status),
                                            ),
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              label: const Text("Delete",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Colors.red),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Delete User'),
                                                    content: const Text(
                                                        'Are you sure you want to delete this user and all their projects?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          _deleteUserCompletely(
                                                              userId);
                                                        },
                                                        child: const Text(
                                                            'Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
