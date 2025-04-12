import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/screens/project.dart';

class ProjectService {
  static Future<void> saveProject(
    BuildContext context,
    String title,
    String description,
    String budget,
    String deadline,
    List<String> skills,
  ) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      String userId = user.uid;
      String projectId =
          FirebaseFirestore.instance.collection('projects').doc().id;

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .set({
        'projectId': projectId,
        'userId': userId,
        'title': title,
        'description': description,
        'budget': double.tryParse(budget) ?? 0.0,
        'preferences': skills,
        'status': 'New',
        'appointedFreelancerId': null,
        'appointedFreelancer': null,
        'appointedTeamId': null,
        'appointedTeam': null,
        'appliedTeams': [],
        'appliedIndividuals': [],
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': deadline,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project added successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProjectScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add project: $e')),
        );
      }
    }
  }
}
