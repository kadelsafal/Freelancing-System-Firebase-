import 'package:flutter/material.dart';
import 'package:freelance_system/Projects/applicants/uploadedFileview.dart';

class ApplicantDetails extends StatelessWidget {
  final Map<String, dynamic> applicant;
  final Map<String, dynamic> projectData;
  final bool isLoading;
  final void Function(String name, String id) onAppoint;

  const ApplicantDetails({
    super.key,
    required this.applicant,
    required this.projectData,
    required this.isLoading,
    required this.onAppoint,
  });

  @override
  Widget build(BuildContext context) {
    final name = applicant['name'] ?? 'Unknown';
    final description = applicant['description'] ?? 'No description';
    final skills = List<String>.from(applicant['skills'] ?? []);
    final uploadedFile = applicant['uploadedFile'] ?? '';
    final userId = applicant['userId'] ?? '';

    final appointedFreelancerId = projectData['appointedFreelancerId'] ?? '';
    final appointedTeam = projectData['appointedTeam'] ?? '';

    bool isButtonDisabled = false;
    String buttonText = "Appoint";
    Color buttonColor = Colors.green;
    Color textColor = Colors.white;
    FontWeight textWeight = FontWeight.normal;

    if (appointedFreelancerId == userId) {
      buttonText = "Appointed";
      isButtonDisabled = true;
    } else if (appointedFreelancerId.isNotEmpty) {
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = Colors.red;
      textWeight = FontWeight.bold;
    }

    if (appointedTeam.isNotEmpty) {
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = Colors.red;
      textWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
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
          if (uploadedFile.isNotEmpty)
            UploadedFileView(uploadedFile: uploadedFile),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isButtonDisabled || isLoading
                  ? null
                  : () => onAppoint(name, userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(buttonText,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: textWeight,
                          color: textColor)),
            ),
          )
        ],
      ),
    );
  }
}
