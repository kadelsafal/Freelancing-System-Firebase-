import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteMilestone extends StatelessWidget {
  final DocumentSnapshot milestone;

  const DeleteMilestone({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Milestone'),
      content: const Text('Are you sure you want to delete this milestone?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await milestone.reference.delete(); // Delete from Firestore
            Navigator.pop(context); // Close the dialog after deletion
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
