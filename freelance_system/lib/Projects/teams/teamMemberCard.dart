import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final int years;
  final String resumeFile;

  const TeamMemberCard({
    super.key,
    required this.member,
    required this.years,
    required this.resumeFile,
  });

  @override
  Widget build(BuildContext context) {
    String userId = member['userId'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Member: ${member['fullName']}",
            style: const TextStyle(fontSize: 16)),
        Text("Experience: $years", style: const TextStyle(fontSize: 16)),
        if (resumeFile.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(resumeFile);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not open file")),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                  Expanded(
                    child: Text(
                      "Click to Open Resume",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.open_in_new, color: Colors.deepPurple),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
