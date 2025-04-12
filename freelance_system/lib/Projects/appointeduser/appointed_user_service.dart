// appointed_user_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _clearSubCollection(
    String projectId, String collectionName) async {
  try {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection(collectionName)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  } catch (e) {
    debugPrint("Error clearing \$collectionName: \$e");
  }
}

Future<bool> showConfirmationDialog(
    BuildContext context, String appointedType) async {
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Remove Appointed \${appointedType.capitalize()}"),
      content: Text(
          "Are you sure you want to remove the appointed \$appointedType?"),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel")),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove")),
      ],
    ),
  );
}

Future<bool> removeAppointedUser({
  required BuildContext context,
  required String projectId,
  required String appointedType,
}) async {
  final updateData = appointedType == 'Freelancer'
      ? {
          'appointedFreelancer': null,
          'appointedFreelancerId': null,
          'status': 'New'
        }
      : {'appointedTeam': null, 'appointedTeamId': null, 'status': 'New'};

  try {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update(updateData);

    await Future.wait([
      _clearSubCollection(projectId, 'issues'),
      _clearSubCollection(projectId, 'statusUpdates'),
      _clearSubCollection(projectId, 'milestones'),
    ]);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Appointed \${appointedType.capitalize()} removed successfully.")),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Error removing appointed \${appointedType.capitalize()}: \$e")),
      );
    }
    return false;
  }
}

int calculateUnseenStatusCount(
    AsyncSnapshot<QuerySnapshot> snapshot, String currentUserName) {
  if (!snapshot.hasData) return 0;

  return snapshot.data!.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final seenBy = List<String>.from(data['isSeenBy'] ?? []);
    final senderName = data['senderName'];

    return senderName != currentUserName && !seenBy.contains(currentUserName);
  }).length;
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}
