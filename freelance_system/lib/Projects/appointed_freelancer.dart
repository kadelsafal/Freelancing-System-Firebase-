// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:freelance_system/Projects/tabs/issues_tab.dart';
// import 'package:freelance_system/Projects/tabs/milestone_tab.dart';
// import 'package:freelance_system/Projects/tabs/status/status_tab.dart';

// import 'package:freelance_system/providers/userProvider.dart';
// import 'package:provider/provider.dart';

// // Extension to capitalize strings
// extension StringCasingExtension on String {
//   String capitalize() {
//     if (isEmpty) return '';
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }

// class AppointedUser extends StatefulWidget {
//   final String projectId;
//   final String appointedName;
//   final String appointedType; // 'freelancer' or 'team'
//   final VoidCallback onAppointedUserRemoved;

//   const AppointedUser({
//     super.key,
//     required this.projectId,
//     required this.appointedName,
//     required this.appointedType,
//     required this.onAppointedUserRemoved,
//   });

//   @override
//   State<AppointedUser> createState() => _AppointedUserState();
// }

// class _AppointedUserState extends State<AppointedUser>
//     with TickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _clearSubCollection(String collectionName) async {
//     try {
//       var querySnapshot = await FirebaseFirestore.instance
//           .collection('projects')
//           .doc(widget.projectId)
//           .collection(collectionName)
//           .get();

//       for (var doc in querySnapshot.docs) {
//         await doc.reference.delete();
//       }
//     } catch (e) {
//       print("Error clearing $collectionName: $e");
//     }
//   }

//   Future<void> _removeAppointed() async {
//     bool confirm = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Remove Appointed ${widget.appointedType.capitalize()}"),
//         content: Text(
//             "Are you sure you want to remove the appointed ${widget.appointedType}?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Remove"),
//           ),
//         ],
//       ),
//     );

//     if (confirm) {
//       final updateData = widget.appointedType == 'Freelancer'
//           ? {
//               'appointedFreelancer': null,
//               'appointedFreelancerId': null,
//               'status': 'New'
//             }
//           : {'appointedTeam': null, 'appointedTeamId': null, 'status': 'New'};

//       try {
//         await FirebaseFirestore.instance
//             .collection('projects')
//             .doc(widget.projectId)
//             .update(updateData);

//         await Future.wait([
//           _clearSubCollection('issues'),
//           _clearSubCollection('statusUpdates'),
//           _clearSubCollection('milestones'),
//         ]);

//         widget.onAppointedUserRemoved();

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Appointed ${widget.appointedType.capitalize()} removed successfully."),
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Error removing appointed ${widget.appointedType.capitalize()}: $e"),
//             ),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Appointed ${widget.appointedType.capitalize()}",
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             CircleAvatar(
//               backgroundColor: Colors.purple,
//               child: Text(
//                 widget.appointedName.isNotEmpty ? widget.appointedName[0] : '?',
//                 style: const TextStyle(color: Colors.white, fontSize: 18),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               widget.appointedName,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Spacer(),
//           ],
//         ),
//         const SizedBox(height: 20),
//         Center(
//           child: ElevatedButton(
//             onPressed: _removeAppointed,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade600,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text("Remove ${widget.appointedType.capitalize()}"),
//           ),
//         ),
//         const SizedBox(height: 10),
//         const Divider(thickness: 1),
//         const SizedBox(height: 10),

//         // StreamBuilder for unseen count
//         Consumer<Userprovider>(
//           builder: (context, userProvider, _) {
//             final currentUserName =
//                 userProvider.userName; // Assuming userProvider gives user name
//             print("Current userName: $currentUserName");

//             return StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('projects')
//                   .doc(widget.projectId)
//                   .collection('statusUpdates')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 int unseenCount = 0;

//                 if (snapshot.hasData) {
//                   final updates = snapshot.data!.docs;

//                   // Iterate over the updates and calculate unseen messages for the current user
//                   unseenCount = updates.where((doc) {
//                     final data = doc.data() as Map<String, dynamic>;
//                     final seenBy = List<String>.from(data['isSeenBy'] ?? []);
//                     final senderName = data['senderName'];

//                     // Check if the current user's name is NOT in the 'isSeenBy' list and the message is not from the current user
//                     bool isUnseen = senderName != currentUserName &&
//                         !seenBy.contains(currentUserName);

//                     // Print the senderName and unseen status for each message
//                     print(
//                         "Status senderName: $senderName, Unseen by $currentUserName: $isUnseen");

//                     return isUnseen;
//                   }).length;

//                   // Print the unseen count for the current user
//                   print("Unseen count for $currentUserName: $unseenCount");
//                 }

//                 return SizedBox(
//                   height: 50,
//                   child: TabBar(
//                     controller: _tabController,
//                     labelColor: Colors.deepPurple,
//                     unselectedLabelColor: Colors.grey,
//                     tabs: [
//                       const Tab(text: "Milestone"),
//                       const Tab(text: "Issues"),
//                       Tab(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text("Status"),
//                             if (unseenCount > 0) ...[
//                               const SizedBox(width: 6),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 6, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   unseenCount.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         ),

//         ConstrainedBox(
//           constraints: const BoxConstraints(minHeight: 150),
//           child: SizedBox(
//             height: 800,
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 MilestoneTab(projectId: widget.projectId),
//                 IssuesTab(projectId: widget.projectId, role: 'client'),
//                 StatusTab(
//                   projectId: widget.projectId,
//                   role: 'client',
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
