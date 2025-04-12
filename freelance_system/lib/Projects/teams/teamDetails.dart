import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/teams/appointteam.dart';
import 'package:freelance_system/Projects/teams/teamMemberCard.dart';

class TeamDetails extends StatefulWidget {
  final Map<String, dynamic> team;
  final String projectId;

  const TeamDetails({
    super.key,
    required this.team,
    required this.projectId,
  });

  @override
  State<TeamDetails> createState() => _TeamDetailsState();
}

class _TeamDetailsState extends State<TeamDetails> {
  bool isLoading = false;
  Map<String, dynamic>? projectData;
  Map<String, String> memberResumeFiles = {};

  @override
  void initState() {
    super.initState();
    fetchProjectData();
  }

  Future<void> fetchProjectData() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (doc.exists) {
      setState(() {
        projectData = doc.data();
      });
      fetchMemberResumeFiles();
    }
  }

  Future<void> fetchMemberResumeFiles() async {
    for (var member in widget.team['members']) {
      String userId = member['userId'];
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          memberResumeFiles[userId] = userDoc.data()?['resume_file'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String teamName = widget.team['teamName'] ?? 'Unnamed Team';
    List<dynamic> members = widget.team['members'] ?? [];

    if (projectData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String appointedTeamId = projectData!['appointedTeamId'] ?? '';
    String appointedFreelancerID = projectData!['appointedFreelancerId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Experience Years",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ...members.map((member) {
              String userId = member['userId'];
              dynamic experienceYears = member['experienceYears'];
              int years = 0;

              if (experienceYears is List) {
                years = experienceYears.isNotEmpty
                    ? int.tryParse(experienceYears[0].toString()) ?? 0
                    : 0;
              } else if (experienceYears is String) {
                years = int.tryParse(experienceYears) ?? 0;
              } else if (experienceYears is int) {
                years = experienceYears;
              }

              String resumeFile = memberResumeFiles[userId] ?? '';

              return TeamMemberCard(
                member: member,
                years: years,
                resumeFile: resumeFile,
              );
            }).toList(),
            const Spacer(),
            AppointButton(
              isLoading: isLoading,
              appointedTeamId: appointedTeamId,
              teamId: widget.team['teamId'] ?? 'Unknown',
              projectId: widget.projectId,
              teamName: teamName,
            ),
          ],
        ),
      ),
    );
  }
}
