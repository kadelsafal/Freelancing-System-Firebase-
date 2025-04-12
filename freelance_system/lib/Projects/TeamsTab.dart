// import 'package:flutter/material.dart';
// import 'teamdetails.dart'; // Make sure to import your TeamDetails widget

// class Teamstab extends StatefulWidget {
//   final String projectId;
//   final List<dynamic> appliedTeams; // Expecting a list of maps for teams

//   const Teamstab(
//       {super.key, required this.projectId, required this.appliedTeams});

//   @override
//   State<Teamstab> createState() => _TeamstabState();
// }

// class _TeamstabState extends State<Teamstab> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: widget.appliedTeams.isEmpty
//           ? const Center(child: Text('No teams applied.')) // Handle empty list
//           : ListView.builder(
//               itemCount: widget
//                   .appliedTeams.length, // Use appliedTeams passed from widget
//               itemBuilder: (context, index) {
//                 var team = widget.appliedTeams[index];
//                 String teamName = team['teamName'] ?? 'Unnamed Team';
//                 String teamId = team['teamId'] ?? 'Unknown';
//                 List<dynamic> members = team['members'] ?? [];

//                 // Set initial status to 'On Hold'
//                 String status = 'On Hold';

//                 // Example check for appointed team status
//                 String appointedTeam =
//                     'Appointed Team Name'; // Modify based on actual logic
//                 String appointedTeamId =
//                     'Appointed Team ID'; // Modify based on actual logic
//                 if (appointedTeam.isNotEmpty && appointedTeamId.isNotEmpty) {
//                   if (teamName == appointedTeam && teamId == appointedTeamId) {
//                     status = 'Appointed';
//                   } else {
//                     status = 'Rejected';
//                   }
//                 }

//                 final bool isRejected = status == 'Rejected';
//                 final bool isAppointed = status == 'Appointed';

//                 Color? cardColor = isRejected
//                     ? const Color.fromRGBO(233, 228, 229, 1)
//                     : Colors.white;

//                 return InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => TeamDetails(
//                           team: team,
//                           projectId: widget.projectId,
//                         ),
//                       ),
//                     );
//                   },
//                   child: Card(
//                     color: cardColor,
//                     elevation: 2,
//                     margin:
//                         const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             teamName,
//                             style: const TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 6),
//                           Text("Status: $status"),
//                           const SizedBox(height: 6),
//                           const Text("Team Members:"),
//                           const SizedBox(height: 4),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: members.map((member) {
//                               String memberName =
//                                   member['fullName'] ?? 'Unknown';
//                               List<dynamic> skills = member['skills'] ?? [];

//                               return Padding(
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 4.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       memberName,
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                     Wrap(
//                                       spacing: 6,
//                                       children: skills
//                                           .map((skill) => Chip(
//                                               label: Text(skill.toString())))
//                                           .toList(),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 12),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
