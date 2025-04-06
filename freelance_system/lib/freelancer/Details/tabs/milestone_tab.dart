import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MilestoneTab extends StatelessWidget {
  const MilestoneTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc('projectId') // Replace with the actual project ID
            .collection('milestones')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, milestoneSnapshot) {
          if (milestoneSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (milestoneSnapshot.hasError) {
            return Center(child: Text("Error: ${milestoneSnapshot.error}"));
          } else if (!milestoneSnapshot.hasData ||
              milestoneSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No milestones created"));
          } else {
            return Column(
              children: milestoneSnapshot.data!.docs.map((doc) {
                var milestoneData = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(milestoneData['author']),
                  subtitle: Text(milestoneData['milestoneText']),
                  trailing: Text(milestoneData['status']),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
