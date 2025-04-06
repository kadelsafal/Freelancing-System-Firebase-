import 'package:flutter/material.dart';

import 'package:freelance_system/Projects/applicants.dart';
import 'package:url_launcher/url_launcher.dart';

class AllApplicants extends StatelessWidget {
  final List<dynamic> applicants;
  final String appointedFreelancer;
  final String projectId;

  const AllApplicants(
      {super.key,
      required this.applicants,
      required this.appointedFreelancer,
      required this.projectId});

  @override
  Widget build(BuildContext context) {
    List<dynamic> sortedApplicants = List.from(applicants);
    sortedApplicants.sort((a, b) {
      if (a['name'] == appointedFreelancer) return -1;
      if (b['name'] == appointedFreelancer) return 1;
      return 0;
    });

    return ListView.builder(
      itemCount: sortedApplicants.length,
      itemBuilder: (context, index) {
        var applicant = sortedApplicants[index];
        String name = applicant['name'] ?? 'Unknown';

        List<dynamic> skills = applicant['skills'] ?? [];
        String uploadedFile = applicant['uploadedFile'] ?? '';

        String status = 'On Hold';
        if (appointedFreelancer.isNotEmpty) {
          status = (name == appointedFreelancer) ? 'Appointed' : 'Rejected';
        }

        final bool isRejected = status == 'Rejected';
        final bool isAppointed = status == 'Appointed';

        Color? cardColor = isRejected
            ? const Color.fromARGB(255, 255, 205, 210)
            : Colors.white;

        return Stack(
          children: [
            Card(
              color: cardColor,
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

            // Status Badge
            if (isRejected || isAppointed)
              Positioned(
                bottom: 12,
                left: 20,
                child: Row(
                  children: [
                    Icon(
                      isRejected ? Icons.close : Icons.check_circle,
                      color: isRejected ? Colors.red : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRejected ? "Rejected" : "Appointed",
                      style: TextStyle(
                        color: isRejected ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
