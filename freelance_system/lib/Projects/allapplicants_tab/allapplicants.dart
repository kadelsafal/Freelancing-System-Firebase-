import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/allapplicants_tab/individualapplicant.dart';
import 'package:freelance_system/Projects/allapplicants_tab/teamapplicant.dart';
import 'package:freelance_system/Projects/applicants.dart';
import 'package:freelance_system/Projects/teamdetails.dart';
import 'package:url_launcher/url_launcher.dart';

class AllApplicants extends StatelessWidget {
  final List<dynamic> applicants;
  final List<dynamic> appliedTeams;
  final String appointedFreelancer;
  final String appointedFreelancerId;
  final String appointedTeam;
  final String appointedTeamId;
  final String projectId;

  const AllApplicants({
    super.key,
    required this.applicants,
    required this.appliedTeams,
    required this.appointedFreelancer,
    required this.projectId,
    required this.appointedTeam,
    required this.appointedTeamId,
    required this.appointedFreelancerId,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> allApplicantWidgets = [];

    List<dynamic> sortedIndividuals = List.from(applicants);
    sortedIndividuals.sort((a, b) {
      if (a['name'] == appointedFreelancer) return -1;
      if (b['name'] == appointedFreelancer) return 1;
      return 0;
    });

    allApplicantWidgets.addAll(_buildIndividualApplicants(sortedIndividuals));
    allApplicantWidgets.addAll(_buildTeamApplicants(appliedTeams));

    return ListView(
      children: allApplicantWidgets,
    );
  }

  List<Widget> _buildIndividualApplicants(List<dynamic> sortedIndividuals) {
    List<Widget> individualWidgets = [];

    for (var applicant in sortedIndividuals) {
      individualWidgets.add(IndividualApplicantCard(
        applicant: applicant,
        projectId: projectId,
      ));
    }

    return individualWidgets;
  }

  List<Widget> _buildTeamApplicants(List<dynamic> appliedTeams) {
    List<Widget> teamWidgets = [];

    for (var team in appliedTeams) {
      teamWidgets.add(TeamApplicantCard(team: team, projectId: projectId));
    }

    return teamWidgets;
  }
}
