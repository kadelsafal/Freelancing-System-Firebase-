import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class Applicants extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final String projectId;

  const Applicants({
    super.key,
    required this.applicant,
    required this.projectId,
  });

  @override
  State<Applicants> createState() => _ApplicantsState();
}

class _ApplicantsState extends State<Applicants> {
  bool isLoading = false;
  Map<String, dynamic>? projectData;

  @override
  void initState() {
    super.initState();
    fetchProjectData();
  }

  // Fetch project data from Firestore
  Future<void> fetchProjectData() async {
    final doc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .get();

    if (doc.exists) {
      setState(() {
        projectData = doc.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String applicantName = widget.applicant['name'] ?? 'Unknown';
    String description =
        widget.applicant['description'] ?? 'No description provided';
    List<String> skills = List<String>.from(widget.applicant['skills'] ?? []);
    String uploadedFile = widget.applicant['uploadedFile'] ?? '';
    String userId = widget.applicant['userId'] ?? 'Unknown';

    if (projectData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String appointedFreelancerID = projectData!['appointedFreelancerId'] ?? '';
    String appointedTeam = projectData!['appointedTeam'] ?? '';

    // Determine button label and style
    String buttonText = "Appoint";
    Color buttonColor = Colors.green;
    Color textColor = Colors.white;
    bool isButtonDisabled = false;
    FontWeight textWeight = FontWeight.normal;

    // Check if the current freelancer is already appointed
    if (appointedFreelancerID == userId) {
      buttonText = "Appointed";
      isButtonDisabled = true;
    } else if (appointedFreelancerID.isNotEmpty &&
        appointedFreelancerID != userId) {
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = const Color.fromARGB(255, 255, 31, 31);
      textWeight = FontWeight.bold;
    }

    // Check if a team is appointed, if so disable the freelancer appointment
    if (appointedTeam.isNotEmpty) {
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = const Color.fromARGB(255, 255, 31, 31);
      textWeight = FontWeight.bold;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Applicant Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              applicantName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text("Skills",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6.0,
              children: skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.deepPurple.shade100,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            if (uploadedFile.isNotEmpty) ...[
              const Text(
                "Uploaded File",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(uploadedFile);
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isButtonDisabled || isLoading
                    ? null
                    : () => appointFreelancer(applicantName, userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        buttonText,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: textWeight,
                            color: textColor),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to appoint a freelancer
  Future<void> appointFreelancer(
      String freelancerName, String freelancerId) async {
    setState(() => isLoading = true);
    try {
      // If a team is appointed, reject the freelancer appointment
      String appointedTeam = projectData!['appointedTeam'] ?? '';
      if (appointedTeam.isNotEmpty) {
        // Reject team appointment by clearing the appointed team
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({
          'appointedTeam': '',
          'appointedTeamId': '',
        });
      }

      // Appoint the freelancer
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'appointedFreelancer': freelancerName,
        'appointedFreelancerId': freelancerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Freelancer Appointed!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
