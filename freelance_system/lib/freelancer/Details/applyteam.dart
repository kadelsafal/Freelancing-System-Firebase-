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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Choose Your Team",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "You are not a member of any team",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text("Create a Team"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final teams = snapshot.data!.docs;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Select a team to apply together",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final isSelected = selectedTeamId == team.id;

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: isSelected ? 4 : 1,
                          color:
                              isSelected ? Colors.blue.shade50 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedTeamId = team.id;
                              });
                              _showTeamMembers(team);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.group,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          team['teamName'] ?? 'Unnamed Team',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.blue.shade700
                                                : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "${team['members'].length} members",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (!isLoadingMore && teams.length == teamLimit)
                    TextButton.icon(
                      onPressed: _loadMoreTeams,
                      icon: Icon(Icons.refresh, color: Colors.blue),
                      label: Text(
                        "Load more teams",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: selectedTeamId == null
                          ? null
                          : () async {
                              if (selectedTeamId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Please select a team before submitting."),
                                    backgroundColor: Colors.red,
                                  ),
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
                                    SnackBar(
                                      content: Text("Team not found."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final teamData = teamDoc.data()!;
                                final teamName =
                                    teamData['teamName'] ?? 'Unnamed Team';
                                final memberIds = List<String>.from(
                                    teamData['members'] ?? []);

                                List<Map<String, dynamic>> teamMemberDetails =
                                    [];

                                for (String memberId in memberIds) {
                                  final userDoc = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(memberId)
                                      .get();

                                  if (userDoc.exists) {
                                    final userData = userDoc.data()!;
                                    final resumeEntities =
                                        userData['resume_entities']
                                            as Map<String, dynamic>?;

                                    if (resumeEntities != null) {
                                      teamMemberDetails.add({
                                        'userId': memberId,
                                        'fullName':
                                            userData['Full Name'] ?? 'Unknown',
                                        'skills':
                                            resumeEntities['SKILLS'] ?? [],
                                        'workedAs':
                                            resumeEntities['WORKED AS'] ?? [],
                                        'experienceYears': resumeEntities[
                                                'YEARS OF EXPERIENCE'] ??
                                            [],
                                      });
                                    } else {
                                      teamMemberDetails.add({
                                        'userId': memberId,
                                        'fullName':
                                            userData['Full Name'] ?? 'Unknown',
                                        'skills': [],
                                        'workedAs': [],
                                        'experienceYears': [],
                                      });
                                    }
                                  }
                                }

                                final projectDoc = await FirebaseFirestore
                                    .instance
                                    .collection('projects')
                                    .doc(widget.projectId)
                                    .get();

                                final appliedTeams =
                                    List<Map<String, dynamic>>.from(
                                        projectDoc.data()?['appliedTeams'] ??
                                            []);

                                final alreadyApplied = appliedTeams.any(
                                    (team) =>
                                        team['teamId'] != null &&
                                        team['teamId'] == selectedTeamId);

                                if (alreadyApplied) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "This team has already applied to this project."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

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
                                    content: Text(
                                        "Team application submitted successfully!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to apply: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        "Submit Application",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTeamMembers(DocumentSnapshot team) async {
    final members = team['members'] as List;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.group, color: Colors.blue),
              SizedBox(width: 8),
              Text("Team Members"),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
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
                    final profileImage = data['profile_image'] as String?;

                    return ListTile(
                      leading: profileImage != null && profileImage.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(profileImage),
                              onBackgroundImageError: (_, __) {
                                // If image fails to load, show initials
                                setState(() {
                                  // Force rebuild with initials
                                });
                              },
                              child:
                                  profileImage == null || profileImage.isEmpty
                                      ? Text(
                                          memberName[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                memberName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      title: Text(
                        memberName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: isAdmin
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Admin",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }
}
