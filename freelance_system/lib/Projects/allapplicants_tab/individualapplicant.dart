import 'package:flutter/material.dart';

import 'package:freelance_system/Projects/applicants/applicants_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class IndividualApplicantCard extends StatelessWidget {
  final dynamic applicant;
  final String projectId;

  const IndividualApplicantCard(
      {super.key, required this.applicant, required this.projectId});

  @override
  Widget build(BuildContext context) {
    String name = applicant['name'] ?? 'Unknown';
    List<dynamic> skills = applicant['skills'] ?? [];
    String uploadedFile = applicant['uploadedFile'] ?? '';

    String status = 'On Hold'; // Logic for status

    return Stack(
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("Status: $status",
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                if (skills.isNotEmpty) ...[
                  const Text("Skills:"),
                  Wrap(
                    spacing: 6,
                    children: skills
                        .map((skill) => Chip(label: Text(skill.toString())))
                        .toList(),
                  ),
                ],
              ],
            ),
            trailing: uploadedFile.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: () async {
                      final uri = Uri.parse(uploadedFile);
                      if (!await launchUrl(uri)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Could not open resume")),
                        );
                      }
                    },
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Applicants(
                    applicant: applicant,
                    projectId: projectId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
