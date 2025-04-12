import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FreelancerService {
  static Future<void> appointFreelancer({
    required BuildContext context,
    required String projectId,
    required String freelancerName,
    required String freelancerId,
    required Map<String, dynamic> projectData,
  }) async {
    try {
      String appointedTeam = projectData['appointedTeam'] ?? '';
      if (appointedTeam.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({'appointedTeam': '', 'appointedTeamId': ''});
      }

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'appointedFreelancer': freelancerName,
        'appointedFreelancerId': freelancerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Freelancer Appointed!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      rethrow;
    }
  }
}
