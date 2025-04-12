// import 'package:flutter/material.dart';
// import 'package:freelance_system/Projects/applicants.dart';
// // Import the team details screen
// import 'package:freelance_system/Projects/teamdetails.dart';
// import 'package:url_launcher/url_launcher.dart';

// class AllApplicants extends StatelessWidget {
//   final List<dynamic> applicants; // appliedIndividuals
//   final List<dynamic> appliedTeams;
//   final String appointedFreelancer;
//   final String appointedFreelancerId;
//   final String appointedTeam;
//   final String appointedTeamId;
//   final String projectId;

//   const AllApplicants({
//     super.key,
//     required this.applicants,
//     required this.appliedTeams,
//     required this.appointedFreelancer,
//     required this.projectId,
//     required this.appointedTeam,
//     required this.appointedTeamId,
//     required this.appointedFreelancerId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     List<Widget> allApplicantWidgets = [];

//     // Sort individuals (appointed on top)
//     List<dynamic> sortedIndividuals = List.from(applicants);
//     sortedIndividuals.sort((a, b) {
//       if (a['name'] == appointedFreelancer) return -1;
//       if (b['name'] == appointedFreelancer) return 1;
//       return 0;
//     });

//     // INDIVIDUAL APPLICANTS
//     for (var applicant in sortedIndividuals) {
//       String name = applicant['name'] ?? 'Unknown';
//       List<dynamic> skills = applicant['skills'] ?? [];
//       String uploadedFile = applicant['uploadedFile'] ?? '';
//       String userId = applicant['userId'];
//       String status = 'On Hold';
//       // If a freelancer is appointed, reject all teams
//       if (appointedFreelancer.isNotEmpty && appointedFreelancerId.isNotEmpty) {
//         status = 'Rejected';
//       } else if (appointedTeam.isNotEmpty && appointedTeamId.isNotEmpty) {
//         // If a team is appointed, reject all freelancers
//         status = 'Rejected';
//       } else if (appointedFreelancer.isNotEmpty &&
//           appointedFreelancerId.isNotEmpty) {
//         // If no team is appointed, set status for the appointed freelancer
//         status =
//             (name == appointedFreelancer && userId == appointedFreelancerId)
//                 ? 'Appointed'
//                 : 'Rejected';
//       }

//       final bool isRejected = status == 'Rejected';
//       final bool isAppointed = status == 'Appointed';

//       Color? cardColor =
//           isRejected ? const Color.fromARGB(255, 255, 205, 210) : Colors.white;

//       allApplicantWidgets.add(
//         Stack(
//           children: [
//             Card(
//               color: cardColor,
//               elevation: 2,
//               margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.deepPurple,
//                   child: Text(
//                     name.isNotEmpty ? name[0] : '?',
//                     style: const TextStyle(color: Colors.white, fontSize: 18),
//                   ),
//                 ),
//                 title: Text(name),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 4),
//                     Text("Status: $status",
//                         style: const TextStyle(fontWeight: FontWeight.w500)),
//                     const SizedBox(height: 4),
//                     if (skills.isNotEmpty) ...[
//                       const Text("Skills:"),
//                       Wrap(
//                         spacing: 6,
//                         children: skills
//                             .map((skill) => Chip(label: Text(skill.toString())))
//                             .toList(),
//                       ),
//                     ],
//                   ],
//                 ),
//                 trailing: uploadedFile.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.picture_as_pdf),
//                         onPressed: () async {
//                           final uri = Uri.parse(uploadedFile);
//                           if (!await launchUrl(uri)) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text("Could not open resume")),
//                             );
//                           }
//                         },
//                       )
//                     : null,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => Applicants(
//                         applicant: applicant,
//                         projectId: projectId,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             if (isRejected || isAppointed)
//               Positioned(
//                 bottom: 12,
//                 left: 20,
//                 child: Row(
//                   children: [
//                     Icon(
//                       isRejected ? Icons.close : Icons.check_circle,
//                       color: isRejected ? Colors.red : Colors.green,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       isRejected ? "Rejected" : "Appointed",
//                       style: TextStyle(
//                         color: isRejected ? Colors.red : Colors.green,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       );
//     }

//     // TEAM APPLICANTS
//     for (var team in appliedTeams) {
//       String teamName = team['teamName'] ?? 'Unnamed Team';
//       String teamId = team['teamId'] ?? 'Unnamed Team';
//       List<dynamic> members = team['members'] ?? [];

//       // Set initial status to 'On Hold'
//       String status = 'On Hold';

//       // If a team is appointed, reject all freelancers
//       if (appointedFreelancer.isNotEmpty && appointedFreelancerId.isNotEmpty) {
//         status = 'Rejected';
//       } else if (appointedTeam.isNotEmpty && appointedTeamId.isNotEmpty) {
//         // If a team is appointed, set the status of this team to 'Appointed'
//         if (teamName == appointedTeam && teamId == appointedTeamId) {
//           status = 'Appointed';
//         } else {
//           status = 'Rejected';
//         }
//       }

//       final bool isRejected = status == 'Rejected';
//       final bool isAppointed = status == 'Appointed';

//       Color? cardColor =
//           isRejected ? const Color.fromARGB(255, 255, 205, 210) : Colors.white;

//       allApplicantWidgets.add(
//         Stack(
//           children: [
//             InkWell(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         TeamDetails(team: team, projectId: projectId),
//                   ),
//                 );
//               },
//               child: Card(
//                 color: cardColor,
//                 elevation: 2,
//                 margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         teamName,
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 6),
//                       Text("Status: $status"),
//                       const SizedBox(height: 6),
//                       const Text("Team Members:"),
//                       const SizedBox(height: 4),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: members.map((member) {
//                           String memberName = member['fullName'] ?? 'Unknown';
//                           List<dynamic> skills = member['skills'] ?? [];

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 4.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   memberName,
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 Wrap(
//                                   spacing: 6,
//                                   children: skills
//                                       .map((skill) =>
//                                           Chip(label: Text(skill.toString())))
//                                       .toList(),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             if (isRejected || isAppointed)
//               Positioned(
//                 bottom: 12,
//                 left: 20,
//                 child: Row(
//                   children: [
//                     Icon(
//                       isRejected ? Icons.close : Icons.check_circle,
//                       color: isRejected ? Colors.red : Colors.green,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       isRejected ? "Rejected" : "Appointed",
//                       style: TextStyle(
//                         color: isRejected ? Colors.red : Colors.green,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       );
//     }

//     return ListView(
//       children: allApplicantWidgets,
//     );
//   }
// }
