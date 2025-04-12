import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ApplyWithTeamModalSheet extends StatefulWidget {
  final String projectId;

  const ApplyWithTeamModalSheet({super.key, required this.projectId});

  @override
  _ApplyWithTeamModalSheetState createState() =>
      _ApplyWithTeamModalSheetState();
}

class _ApplyWithTeamModalSheetState extends State<ApplyWithTeamModalSheet> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoadingMore = false;
  int teamLimit = 3;
  String? selectedTeamId;

  Future<void> _loadMoreTeams() async {
    setState(() {
      isLoadingMore = true;
      teamLimit += 3;
    });

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text("Project not found.");
                }

                final projectTitle =
                    snapshot.data!['title'] ?? 'Unknown Project';

                return Text(
                  "Apply with Team for Project: $projectTitle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Select your team to apply together.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              "Choose Your Team",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .where('members', arrayContains: currentUserId)
                    .limit(teamLimit)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text("You are not a member of any team.");
                  }

                  final teams = snapshot.data!.docs;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final isSelected = selectedTeamId == team.id;

                            return Card(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                title: Text(team['teamName'] ?? 'Unnamed Team'),
                                subtitle:
                                    Text("Members: ${team['members'].length}"),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: Colors.blue)
                                    : Icon(Icons.group),
                                onTap: () {
                                  setState(() {
                                    selectedTeamId = team.id;
                                  });
                                  _showTeamMembers(team);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      if (isLoadingMore)
                        Center(child: CircularProgressIndicator()),
                      if (!isLoadingMore && teams.length == teamLimit)
                        TextButton(
                          onPressed: _loadMoreTeams,
                          child: Text("Load more teams"),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (selectedTeamId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Please select a team before submitting.")),
                  );
                  return;
                }

                try {
                  final teamDoc = await FirebaseFirestore.instance
                      .collection('teams')
                      .doc(selectedTeamId)
                      .get();

                  if (!teamDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Team not found.")),
                    );
                    return;
                  }

                  final teamData = teamDoc.data()!;
                  final teamName = teamData['teamName'] ?? 'Unnamed Team';
                  final memberIds =
                      List<String>.from(teamData['members'] ?? []);

                  List<Map<String, dynamic>> teamMemberDetails = [];

                  // Loop through each team member and fetch their details
                  for (String memberId in memberIds) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(memberId)
                        .get();

                    if (userDoc.exists) {
                      final userData = userDoc.data()!;
                      final resumeEntities =
                          userData['resume_entities'] as Map<String, dynamic>?;

                      // Check if the resumeEntities exists before adding to teamMemberDetails
                      if (resumeEntities != null) {
                        teamMemberDetails.add({
                          'userId': memberId,
                          'fullName': userData['Full Name'] ?? 'Unknown',
                          'skills': resumeEntities['SKILLS'] ?? [],
                          'workedAs': resumeEntities['WORKED AS'] ?? [],
                          'experienceYears':
                              resumeEntities['YEARS OF EXPERIENCE'] ?? [],
                        });
                      } else {
                        // If no resumeEntities, still add the member with minimal data
                        teamMemberDetails.add({
                          'userId': memberId,
                          'fullName': userData['Full Name'] ?? 'Unknown',
                          'skills': [],
                          'workedAs': [],
                          'experienceYears': [],
                        });
                      }
                    }
                  }

                  final projectDoc = await FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.projectId)
                      .get();

                  final appliedTeams = List<Map<String, dynamic>>.from(
                      projectDoc.data()?['appliedTeams'] ?? []);

                  // Check if the team has already applied
                  final alreadyApplied = appliedTeams.any((team) =>
                      team['teamId'] != null &&
                      team['teamId'] == selectedTeamId);

                  if (alreadyApplied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "This team has already applied to this project.")),
                    );
                    return;
                  }

                  // Now update the project document with the new team details
                  await FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.projectId)
                      .update({
                    'appliedTeams': FieldValue.arrayUnion([
                      {
                        'teamId': selectedTeamId,
                        'teamName': teamName,
                        'members': teamMemberDetails,
                      }
                    ]),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text("Team application submitted successfully!")),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to apply: $e")),
                  );
                }
              },
              child: Text("Submit Application as Team"),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamMembers(DocumentSnapshot team) async {
    final members = team['members'] as List;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Team Members"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: members.map<Widget>((memberId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Container();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final memberName = data['Full Name'] ?? 'Unknown';
                  final isAdmin = team['admin'] == memberId;

                  return ListTile(
                    title: Text(memberName),
                    subtitle: isAdmin ? Text("Admin") : null,
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
