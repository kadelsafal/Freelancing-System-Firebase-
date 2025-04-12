import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneService {
  final String projectId;

  MilestoneService(this.projectId);

  // Get milestones stream
  Stream<QuerySnapshot> getMilestonesStream() {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .snapshots();
  }

  // Update subtask status
  Future<void> updateSubtaskStatus(
      DocumentSnapshot milestone, int index, String status) async {
    final updatedSubtasks =
        List<Map<String, dynamic>>.from(milestone['subtasks']);
    updatedSubtasks[index]['status'] = status;

    final completedCount =
        updatedSubtasks.where((s) => s['status'] == 'Completed').length;
    final taskStatus = completedCount == 0
        ? 'Not Completed'
        : completedCount == updatedSubtasks.length
            ? 'Completed'
            : 'In Process';

    await milestone.reference.update({
      'subtasks': updatedSubtasks,
      'status': taskStatus,
    });
  }

  // Delete milestone
  Future<void> deleteMilestone(DocumentSnapshot milestone) async {
    await milestone.reference.delete();
  }

  // Add project URL
  Future<void> addProjectUrl(List<String> urls, String newUrl) async {
    if (urls.length < 5) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({'urls': urls..add(newUrl)});
    }
  }

  // Load project URLs
  Future<List<String>> loadProjectUrls() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();
    return List<String>.from(doc.data()?['urls'] ?? []);
  }
}
