import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamDetails extends StatefulWidget {
  final Map<String, dynamic> team; // Team data passed as Map
  final String projectId;

  const TeamDetails({
    super.key,
    required this.team,
    required this.projectId,
  });

  @override
  State<TeamDetails> createState() => _TeamDetailsState();
}

class _TeamDetailsState extends State<TeamDetails> {
  bool isLoading = false;
  Map<String, dynamic>? projectData;
  Map<String, String> memberResumeFiles =
      {}; // Map to store resume files for members

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
      fetchMemberResumeFiles(); // Fetch the resume files for each team member
    }
  }

  // Fetch the resume file for each team member using their userId
  Future<void> fetchMemberResumeFiles() async {
    for (var member in widget.team['members']) {
      String userId = member['userId'];
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          memberResumeFiles[userId] =
              userDoc.data()?['resume_file'] ?? ''; // Store the resume file URL
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String teamName = widget.team['teamName'] ?? 'Unnamed Team';
    List<dynamic> members = widget.team['members'] ?? [];

    if (projectData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String appointedTeamId = projectData!['appointedTeamId'] ?? '';
    String appointedFreelancerID = projectData!['appointedFreelancerId'] ?? '';

    // Determine button label and style
    String buttonText = "Appoint Team";
    Color buttonColor = Colors.green;
    Color textColor = Colors.white;
    bool isButtonDisabled = false;
    FontWeight textWeight = FontWeight.normal;

    String teamId = widget.team['teamId'] ?? 'Unknown';

    if (appointedTeamId == teamId) {
      buttonText = "Appointed";
      isButtonDisabled = true;
    } else if (appointedFreelancerID.isNotEmpty) {
      // If a freelancer is appointed, disable team appointment
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = const Color.fromARGB(255, 255, 31, 31);
      textWeight = FontWeight.bold;
    } else if (appointedTeamId.isNotEmpty && appointedTeamId != teamId) {
      // If another team is appointed, disable the appointment
      buttonText = "Rejected";
      isButtonDisabled = true;
      textColor = const Color.fromARGB(255, 255, 31, 31);
      textWeight = FontWeight.bold;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Experience Years",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            // Loop through team members and display their experience years and resume file
            ...members.map((member) {
              String userId = member['userId'];

              // Ensure that 'experienceYears' is treated as an integer
              dynamic experienceYears = member['experienceYears'];
              int years = 0;

              if (experienceYears is List) {
                // If it's an array, pick the first element
                years = experienceYears.isNotEmpty
                    ? int.tryParse(experienceYears[0].toString()) ?? 0
                    : 0;
              } else if (experienceYears is String) {
                // If it's a string, parse it to an integer
                years = int.tryParse(experienceYears) ?? 0;
              } else if (experienceYears is int) {
                // If it's already an integer, use it directly
                years = experienceYears;
              }

              String resumeFile = memberResumeFiles[userId] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Member: ${member['fullName']}",
                      style: TextStyle(fontSize: 16)),
                  Text("Experience: $years", style: TextStyle(fontSize: 16)),
                  if (resumeFile.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(resumeFile);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Could not open file")),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.deepPurple, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Icon(Icons.picture_as_pdf,
                                color: Colors.red, size: 28),
                            Expanded(
                              child: Text(
                                "Click to Open Resume",
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
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isButtonDisabled || isLoading
                    ? null
                    : () => appointTeam(teamName, teamId),
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

  Future<void> appointTeam(String teamName, String teamId) async {
    setState(() => isLoading = true);
    try {
      // If a freelancer is already appointed, reject the team
      String appointedFreelancerID =
          projectData!['appointedFreelancerId'] ?? '';
      if (appointedFreelancerID.isNotEmpty) {
        // Reject freelancer appointment
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({
          'appointedFreelancerId': '', // Remove the appointed freelancer
          'appointedFreelancer': '', // Remove the freelancer name
        });
      }

      // Now appoint the team
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'appointedTeam': teamName,
        'appointedTeamId': teamId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Team Appointed!")),
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
