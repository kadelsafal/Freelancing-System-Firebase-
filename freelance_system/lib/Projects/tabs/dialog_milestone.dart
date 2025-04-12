// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class MilestoneDialog extends StatefulWidget {
//   final String projectId;

//   const MilestoneDialog({super.key, required this.projectId});

//   @override
//   State<MilestoneDialog> createState() => _MilestoneDialogState();
// }

// class _MilestoneDialogState extends State<MilestoneDialog> {
//   final List<Map<String, dynamic>> milestones = [];

//   // Controllers for current milestone input
//   final TextEditingController milestoneTitleController =
//       TextEditingController();
//   final TextEditingController subtaskTitleController = TextEditingController();

//   List<Map<String, dynamic>> currentSubtasks = [];
//   DateTime? startDate;
//   DateTime? endDate;

//   // Pick date helper
//   Future<void> _pickDate({required bool isStart}) async {
//     DateTime now = DateTime.now();
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: now,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 5),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           startDate = picked;
//         } else {
//           endDate = picked;
//         }
//       });
//     }
//   }

//   void _addSubtask() {
//     if (subtaskTitleController.text.isNotEmpty &&
//         startDate != null &&
//         endDate != null) {
//       setState(() {
//         currentSubtasks.add({
//           'title': subtaskTitleController.text,
//           'startDate': startDate!.toIso8601String(),
//           'endDate': endDate!.toIso8601String(),
//           'status': 'Not Completed',
//         });
//         subtaskTitleController.clear();
//         startDate = null;
//         endDate = null;
//       });
//     }
//   }

//   void _addMilestone() {
//     if (milestoneTitleController.text.isNotEmpty &&
//         currentSubtasks.isNotEmpty) {
//       setState(() {
//         milestones.add({
//           'title': milestoneTitleController.text,
//           'status': 'Not Completed',
//           'subtasks': List<Map<String, dynamic>>.from(currentSubtasks),
//         });
//         milestoneTitleController.clear();
//         currentSubtasks.clear();
//       });
//     }
//   }

//   void _submitAllMilestones() async {
//     for (var milestone in milestones) {
//       await FirebaseFirestore.instance
//           .collection('projects')
//           .doc(widget.projectId)
//           .collection('milestones')
//           .add(milestone);
//     }
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text("Add Milestone Details"),
//       content: Container(
//         width: 500, // Set the width of the dialog here
//         height: 600, // Set the height of the dialog here
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Text("Milestone ${milestones.length + 1}",
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//               TextField(
//                 controller: milestoneTitleController,
//                 decoration: const InputDecoration(labelText: "Milestone Title"),
//               ),
//               const Divider(),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: subtaskTitleController,
//                       decoration: InputDecoration(
//                         labelText: "Subtask Title",
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.add),
//                           onPressed: _addSubtask,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => _pickDate(isStart: true),
//                       child: Text(startDate == null
//                           ? 'Pick Start Date'
//                           : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}'),
//                     ),
//                   ),
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => _pickDate(isStart: false),
//                       child: Text(endDate == null
//                           ? 'Pick End Date'
//                           : 'End: ${endDate!.toLocal().toString().split(' ')[0]}'),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               ...currentSubtasks.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 var s = entry.value;
//                 String start = s['startDate'] != null
//                     ? s['startDate'].split('T')[0]
//                     : 'N/A';
//                 String end =
//                     s['endDate'] != null ? s['endDate'].split('T')[0] : 'N/A';
//                 return ListTile(
//                   title:
//                       Text("Subtask ${index + 1}: ${s['title'] ?? 'No Title'}"),
//                   subtitle: Text("From: $start To: $end"),
//                 );
//               }),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _addMilestone,
//                 child: const Text("Add Milestone"),
//               ),
//               const Divider(thickness: 1.5),
//               ...milestones.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 var m = entry.value;
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Milestone ${index + 1}: ${m['title']}",
//                         style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ...m['subtasks'].asMap().entries.map((subEntry) {
//                       int subIndex = subEntry.key;
//                       var sub = subEntry.value;
//                       String start = sub['startDate'] != null
//                           ? sub['startDate'].split('T')[0]
//                           : 'N/A';
//                       String end = sub['endDate'] != null
//                           ? sub['endDate'].split('T')[0]
//                           : 'N/A';
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 12.0),
//                         child: ListTile(
//                           title: Text(
//                               "Subtask ${subIndex + 1}: ${sub['title'] ?? 'No Title'}"),
//                           subtitle: Text("From: $start To: $end"),
//                         ),
//                       );
//                     }),
//                     const Divider(),
//                   ],
//                 );
//               }),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         ElevatedButton(
//           onPressed: _submitAllMilestones,
//           child: const Text("Submit All"),
//         ),
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text("Cancel"),
//         )
//       ],
//     );
//   }
// }
