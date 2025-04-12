import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/tabs/status/status_card.dart';

class StatusList extends StatelessWidget {
  final String projectId;
  final String currentName;

  const StatusList(
      {super.key, required this.projectId, required this.currentName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('statusUpdates')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No status updates"));

        return ListView.builder(
          reverse: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return StatusCard(
              statusId: doc.id,
              projectId: projectId,
              data: data,
              currentUser: currentName,
            );
          },
        );
      },
    );
  }
}
