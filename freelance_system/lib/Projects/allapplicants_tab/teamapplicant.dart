import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/teamdetails.dart';
import 'package:freelance_system/Projects/teams/teamDetails.dart';

class TeamApplicantCard extends StatelessWidget {
  final dynamic team;
  final String projectId;

  const TeamApplicantCard(
      {super.key, required this.team, required this.projectId});

  @override
  Widget build(BuildContext context) {
    String teamName = team['teamName'] ?? 'Unnamed Team';
    String teamId = team['teamId'] ?? 'Unnamed Team';
    List<dynamic> members = team['members'] ?? [];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetails(team: team, projectId: projectId),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity, // Full width
        child: Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text("Status: On Hold"),
                const SizedBox(height: 6),
                const Text("Team Members:"),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: members.map((member) {
                    String memberName = member['fullName'] ?? 'Unknown';
                    List<dynamic> skills = member['skills'] ?? [];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 6,
                            children: skills
                                .map((skill) =>
                                    Chip(label: Text(skill.toString())))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
