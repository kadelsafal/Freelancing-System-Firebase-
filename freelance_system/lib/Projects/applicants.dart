import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Applicants extends StatefulWidget {
  final Map<String, dynamic> applicant;
  const Applicants({super.key, required this.applicant});

  @override
  State<Applicants> createState() => _ApplicantsState();
}

class _ApplicantsState extends State<Applicants> {
  @override
  Widget build(BuildContext context) {
    String name = widget.applicant['name'] ?? 'Unknown';
    String description =
        widget.applicant['description'] ?? 'No description provided';
    List<String> skills = List<String>.from(widget.applicant['skills'] ?? []);
    String uploadedFile = widget.applicant['uploadedFile'] ?? '';
    String userId = widget.applicant['userId'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text("Applicant Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            SizedBox(height: 10),

            // Description
            Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),

            // Skills
            Text(
              "Skills",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Wrap(
              spacing: 6.0,
              children: skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.deepPurple.shade100,
                      ))
                  .toList(),
            ),
            SizedBox(height: 10),

            // Uploaded File Preview
            if (uploadedFile.isNotEmpty) ...[
              Text(
                "Uploaded File",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  if (await canLaunchUrl(Uri.parse(uploadedFile))) {
                    await launchUrl(Uri.parse(uploadedFile),
                        mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not open file")),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.deepPurple, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                      Expanded(
                        child: Text(
                          "Click to Open File",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.open_in_new, color: Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
