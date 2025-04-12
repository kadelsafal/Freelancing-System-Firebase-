import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/allapplicants_tab/teamapplicant.dart';

class TeamsTab extends StatelessWidget {
  final List<dynamic> appliedTeams;
  final String projectId;

  const TeamsTab(
      {super.key, required this.appliedTeams, required this.projectId});

  // Method to build team applicant cards
  List<Widget> _buildTeamApplicants(List<dynamic> appliedTeams) {
    List<Widget> teamWidgets = [];

    for (var team in appliedTeams) {
      teamWidgets.add(TeamApplicantCard(team: team, projectId: projectId));
    }

    return teamWidgets;
  }

  @override
  Widget build(BuildContext context) {
    // Directly pass the result of _buildTeamApplicants to ListView
    return ListView(
      children: _buildTeamApplicants(appliedTeams), // No need for an extra list
    );
  }
}
