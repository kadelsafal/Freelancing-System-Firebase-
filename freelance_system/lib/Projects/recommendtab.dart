import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_system/Projects/applicants/applicants_screen.dart';

class Recommended extends StatefulWidget {
  final List<dynamic> applicants;
  final List<dynamic> projectSkills;
  final String projectId; // Add projectId to pass to the Applicants screen

  const Recommended({
    super.key,
    required this.applicants,
    required this.projectSkills,
    required this.projectId, // Initialize projectId here
  });

  @override
  State<Recommended> createState() => _RecommendedState();
}

class _RecommendedState extends State<Recommended> {
  late Future<List<Map<String, dynamic>>> _recommendedFuture;

  @override
  void initState() {
    super.initState();
    _recommendedFuture = _fetchRecommendedApplicants();
  }

  // Function to get skill match count from both `skills` and `resume_entities['SKILLS']`
  int getSkillMatchCount(
      List<dynamic> candidateSkills, List<dynamic> resumeSkills) {
    if (!mounted) return 0;

    // Convert all skills and projectSkills to lowercase for case-insensitive matching
    List<String> projectSkillsLower = widget.projectSkills
        .map((skill) => skill.toString().toLowerCase())
        .toList();
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
    if (!mounted) return 0;

    // Print userId to the console
    print("Fetching experience for user ID: $userId");

    try {
      // Fetch user document by userId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

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
    } catch (e) {
      print('Error fetching experience: $e');
    }

    return 0; // Return 0 if no valid experience is found
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recommendedFuture,
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1976D2),
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Matched Skills: ${data['matchedSkills']}",
                              style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Experience: ${data['experience']} years",
                              style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Applicants(
                                    applicant: candidate,
                                    projectId: widget.projectId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "View Details",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    if (!mounted) return [];

    List<Map<String, dynamic>> recommended = [];

    try {
      // Batch fetch all user documents
      List<String> userIds =
          widget.applicants.map((a) => a['userId'] as String).toList();
      Map<String, DocumentSnapshot> userDocs = {};

      await Future.wait(userIds.map((userId) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        userDocs[userId] = doc;
      }));

      for (var candidate in widget.applicants) {
        if (!mounted) break;

        String userId = candidate['userId'];
        List<dynamic> skills = candidate['skills'] ?? [];

        final userDoc = userDocs[userId];
        List<dynamic> resumeSkills = [];

        if (userDoc?.exists ?? false) {
          final userData = userDoc?.data() as Map<String, dynamic>?;
          if (userData != null && userData['resume_entities'] != null) {
            resumeSkills = userData['resume_entities']['SKILLS'] ?? [];
          }
        }

        final candidateResume = candidate['resume_entities'] ?? {};
        List<dynamic> candidateResumeSkills = candidateResume['SKILLS'] ?? [];

        List<dynamic> allSkills = [
          ...skills,
          ...resumeSkills,
          ...candidateResumeSkills
        ];
        double experience = await extractExperience(userId);
        int matchedSkillCount = getSkillMatchCount(allSkills, []);

        if (matchedSkillCount > 0) {
          recommended.add({
            'candidate': candidate,
            'matchedSkills': matchedSkillCount,
            'experience': experience,
          });
        }
      }

      recommended.sort((a, b) {
        int skillCompare = b['matchedSkills'].compareTo(a['matchedSkills']);
        if (skillCompare != 0) return skillCompare;
        return b['experience'].compareTo(a['experience']);
      });
    } catch (e) {
      print('Error fetching recommended applicants: $e');
    }

    return recommended;
  }
}
