import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'applicants.dart'; // Import the Applicants screen

class Recommended extends StatelessWidget {
  final List<dynamic> applicants;
  final List<dynamic> projectSkills;
  final String projectId; // Add projectId to pass to the Applicants screen

  const Recommended({
    super.key,
    required this.applicants,
    required this.projectSkills,
    required this.projectId, // Initialize projectId here
  });

  // Function to get skill match count from both `skills` and `resume_entities['SKILLS']`
  int getSkillMatchCount(
      List<dynamic> candidateSkills, List<dynamic> resumeSkills) {
    // Convert all skills and projectSkills to lowercase for case-insensitive matching
    List<String> projectSkillsLower =
        projectSkills.map((skill) => skill.toString().toLowerCase()).toList();
    List<String> candidateSkillsLower =
        candidateSkills.map((skill) => skill.toString().toLowerCase()).toList();
    List<String> resumeSkillsLower =
        resumeSkills.map((skill) => skill.toString().toLowerCase()).toList();

    // Matching skills in both fields (applicant's skills and resume_entities' skills)
    int matchInSkills = candidateSkillsLower
        .where((skill) => projectSkillsLower.contains(skill))
        .length;
    int matchInResumeSkills = resumeSkillsLower
        .where((skill) => projectSkillsLower.contains(skill))
        .length;

    return matchInSkills + matchInResumeSkills; // Sum of both matches
  }

  // Function to fetch and extract experience from Firestore for the userId
  Future<double> extractExperience(String userId) async {
    // Print userId to the console
    print("Fetching experience for user ID: $userId");

    // Fetch user document by userId
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final resumeEntities = userDoc.data()?['resume_entities'] ?? {};
      final years = resumeEntities['YEARS OF EXPERIENCE'];

      // Check if years is a list and extract the first element
      if (years is List && years.isNotEmpty) {
        return double.tryParse(years[0].toString()) ?? 0;
      } else if (years is String) {
        return double.tryParse(years) ?? 0;
      }
    }

    return 0; // Return 0 if no valid experience is found
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecommendedApplicants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No recommended applicants"));
        } else {
          List<Map<String, dynamic>> recommended = snapshot.data!;

          return ListView.builder(
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              var data = recommended[index];
              var candidate = data['candidate'];
              String name = candidate['name'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Matched Skills: ${data['matchedSkills']}"),
                      Text("Experience: ${data['experience']} years"),
                    ],
                  ),
                  trailing: const Icon(Icons.recommend, color: Colors.green),
                  onTap: () {
                    // Navigate to Applicants screen and pass the data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Applicants(
                          applicant: candidate, // Pass selected applicant data
                          projectId: projectId, // Pass projectId
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  // Function to fetch and generate the list of recommended applicants
  Future<List<Map<String, dynamic>>> _fetchRecommendedApplicants() async {
    List<Map<String, dynamic>> recommended = [];

    for (var candidate in applicants) {
      List<dynamic> skills = candidate['skills'] ?? [];

      // Fetch resume skills from Firestore
      List<dynamic> resumeSkills = [];
      double experience = await extractExperience(candidate['userId']);
      final resume = candidate['resume_entities'] ?? {};
      resumeSkills = resume['SKILLS'] ?? [];

      // Print userId to the console for debugging
      print("Evaluating userId: ${candidate['userId']}");

      // Get skill matches
      int matchedSkillCount = getSkillMatchCount(skills, resumeSkills);

      if (matchedSkillCount > 0) {
        recommended.add({
          'candidate': candidate,
          'matchedSkills': matchedSkillCount,
          'experience': experience,
        });
      }
    }

    // Sort by matched skills and experience
    recommended.sort((a, b) {
      int skillCompare = b['matchedSkills'].compareTo(a['matchedSkills']);
      if (skillCompare != 0) return skillCompare;
      return b['experience'].compareTo(a['experience']);
    });

    return recommended;
  }
}
