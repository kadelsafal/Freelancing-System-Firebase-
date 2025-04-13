import 'package:flutter/material.dart';
import 'package:freelance_system/admin/coursescreen.dart';
import 'package:freelance_system/admin/projectscreen.dart';
import 'package:freelance_system/admin/userscreen.dart';
import 'package:freelance_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _userCount = 0;
  int _projectCount = 0;
  int _courseCount = 0; // NEW
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final projectSnapshot =
          await FirebaseFirestore.instance.collection('projects').get();
      final coursesnapshot =
          await FirebaseFirestore.instance.collection('courses').get();

      setState(() {
        _userCount = userSnapshot.docs.length;
        _projectCount = projectSnapshot.docs.length;
        _courseCount = coursesnapshot.docs.length; // NEW
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print("🔥 Error fetching counts: $e");
      print(
          stackTrace); // helps pinpoint errors like missing collection or permission denied
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Course'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Project'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                        title: "Total Users",
                        count: _userCount,
                        icon: Icons.people,
                        color: Colors.blueAccent,
                      ),
                      _buildStatCard(
                        title: "Total Projects",
                        count: _projectCount,
                        icon: Icons.work_outline,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: "Total Courses",
                        count: _courseCount,
                        icon: Icons.book_online_outlined,
                        color: const Color.fromARGB(255, 139, 214, 141),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome to the Admin Panel!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
