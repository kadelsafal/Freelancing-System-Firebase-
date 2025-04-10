import 'package:flutter/material.dart';

class Recommended extends StatelessWidget {
  final List<dynamic> applicants;
  final List<dynamic> teams;
  final List<dynamic> projectSkills; // Expected to be a List of Strings

  const Recommended({
    super.key,
    required this.applicants,
    required this.teams,
    required this.projectSkills,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> recommendedWidgets = [];

    // Helper function to calculate skill match percentage
    double calculateSkillMatch(
        List<dynamic> skills, List<dynamic> projectSkills) {
      int matchedSkills =
          skills.where((skill) => projectSkills.contains(skill)).length;
      return matchedSkills / projectSkills.length * 100;
    }

    // Sort and filter applicants based on skills match and experience
    List<dynamic> allCandidates = [...applicants, ...teams];

    // Filter out candidates who don't meet the minimum skill match and experience
    allCandidates = allCandidates.where((candidate) {
      List<dynamic> skills = candidate['skills'] ?? [];
      double skillMatch = calculateSkillMatch(skills, projectSkills);
      double experience =
          double.tryParse(candidate['yearsOfExperience'].toString()) ?? 0;

      // Define the skill match threshold (e.g., 70% or higher) and minimum experience (e.g., 2 years)
      return skillMatch >= 70 && experience >= 2;
    }).toList();

    // Sort by experience in descending order
    allCandidates.sort((a, b) {
      double experienceA =
          double.tryParse(a['yearsOfExperience'].toString()) ?? 0;
      double experienceB =
          double.tryParse(b['yearsOfExperience'].toString()) ?? 0;
      return experienceB
          .compareTo(experienceA); // Sort by experience in descending order
    });

    // Loop through the filtered and sorted applicants and teams
    for (var candidate in allCandidates) {
      String name = candidate['name'] ?? 'Unknown';
      List<dynamic> skills = candidate['skills'] ?? [];
      double skillMatch = calculateSkillMatch(skills, projectSkills);
      String status = 'Recommended';

      // Add details based on whether the candidate is an individual or team
      if (candidate['userId'] != null) {
        recommendedWidgets.add(
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: $status"),
                Text("Skills Match: ${skillMatch.toStringAsFixed(2)}%"),
                Text("Experience: ${candidate['yearsOfExperience']} years"),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to candidate details
            },
          ),
        );
      } else {
        recommendedWidgets.add(
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(name.isNotEmpty ? name[0] : '?',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: $status"),
                Text("Skills Match: ${skillMatch.toStringAsFixed(2)}%"),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to team details
            },
          ),
        );
      }
    }

    return recommendedWidgets.isNotEmpty
        ? ListView(children: recommendedWidgets)
        : Center(child: Text("No recommended applicants"));
  }
}
