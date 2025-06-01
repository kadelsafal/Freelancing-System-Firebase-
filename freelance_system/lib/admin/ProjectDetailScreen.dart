import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot projectDoc;
  const ProjectDetailScreen({Key? key, required this.projectDoc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = projectDoc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? 'No Description';
    final deadline = data['deadline'] ?? 'N/A';
    final userId = data['userId'];
    final appointedFreelancer = data['appointedFreelancer'];
    final appointedFreelancerId = data['appointedFreelancerId'];
    final appointedTeam = data['appointedTeam'];
    final appointedTeamId = data['appointedTeamId'];
    final applicants = ((data['appliedIndividuals'] as List?)?.length ?? 0) +
        ((data['appliedTeams'] as List?)?.length ?? 0);
    final status = data['status'] ?? 'Pending';
    final budget = data['budget'] ?? 'N/A';
    final projectId = projectDoc.id;
    final preferences = data['preferences'] as List?;
    final appliedIndividuals = (data['appliedIndividuals'] as List?) ?? [];
    final appliedTeams = (data['appliedTeams'] as List?) ?? [];

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          String postedBy = 'Unknown';
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            postedBy = userData['Full Name'] ?? 'Unknown';
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: status == 'Completed'
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text('Deadline: $deadline',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text('Budget: $budget',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text('Applicants: $applicants',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.description,
                                      color: Colors.blue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    appointedFreelancer != null
                                        ? Icons.person
                                        : Icons.groups,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appointedFreelancer != null
                                        ? 'Appointed Freelancer'
                                        : appointedTeam != null
                                            ? 'Appointed Team'
                                            : 'No Appointment',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (appointedFreelancer != null &&
                                  appointedFreelancerId != null) ...[
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(appointedFreelancerId)
                                      .get(),
                                  builder: (context, appointedSnapshot) {
                                    String? profileImage;
                                    if (appointedSnapshot.hasData &&
                                        appointedSnapshot.data!.exists) {
                                      final userData = appointedSnapshot.data!
                                          .data() as Map<String, dynamic>;
                                      profileImage =
                                          userData['profileImage'] as String?;
                                    }
                                    return Row(
                                      children: [
                                        profileImage != null &&
                                                profileImage.isNotEmpty
                                            ? CircleAvatar(
                                                backgroundImage:
                                                    NetworkImage(profileImage),
                                                radius: 24,
                                              )
                                            : CircleAvatar(
                                                backgroundColor:
                                                    const Color(0xFF1976D2),
                                                radius: 24,
                                                child: Text(
                                                  appointedFreelancer.isNotEmpty
                                                      ? appointedFreelancer[0]
                                                      : '?',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18),
                                                ),
                                              ),
                                        const SizedBox(width: 12),
                                        Text(
                                          appointedFreelancer,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ] else if (appointedFreelancer != null) ...[
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF1976D2),
                                      radius: 24,
                                      child: Text(
                                        appointedFreelancer.isNotEmpty
                                            ? appointedFreelancer[0]
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      appointedFreelancer,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ] else if (appointedTeam != null &&
                                  appointedTeamId != null) ...[
                                // Optionally, you can add a similar block for appointedTeam profile image if you store it
                                Text(appointedTeam.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ] else ...[
                                Text('No freelancer or team appointed yet.',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[800])),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Posted By',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                postedBy,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Project ID',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                projectId,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (preferences != null && preferences.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.tune, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Preferences',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: preferences
                                      .map<Widget>((pref) => Chip(
                                            label: Text(pref.toString()),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            labelStyle: const TextStyle(
                                                color: Color(0xFF1976D2)),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (appliedIndividuals.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.person, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Applied Applicants',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: appliedIndividuals
                                      .map<Widget>((applicant) {
                                    if (applicant is! Map)
                                      return const SizedBox.shrink();
                                    final userId =
                                        applicant['userId'] as String?;
                                    final name = applicant['name'] ??
                                        applicant['fullName'] ??
                                        'Unknown';
                                    final description =
                                        applicant['description'] ?? '';
                                    final skills =
                                        (applicant['skills'] as List?)
                                                ?.cast<String>() ??
                                            [];
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: userId != null
                                          ? FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .get()
                                          : null,
                                      builder: (context, userSnapshot) {
                                        String? profileImage;
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!
                                              .data() as Map<String, dynamic>;
                                          profileImage =
                                              userData['profileImage']
                                                  as String?;
                                        }
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                profileImage != null &&
                                                        profileImage.isNotEmpty
                                                    ? CircleAvatar(
                                                        backgroundImage:
                                                            NetworkImage(
                                                                profileImage),
                                                        radius: 28,
                                                      )
                                                    : CircleAvatar(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF1976D2),
                                                        radius: 28,
                                                        child: Text(
                                                          name.isNotEmpty
                                                              ? name[0]
                                                              : '?',
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(name,
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      16)),
                                                      if (description
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(description,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey[700],
                                                                fontSize: 14)),
                                                      ],
                                                      if (skills
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 8),
                                                        Wrap(
                                                          spacing: 8,
                                                          children: skills
                                                              .map((s) => Chip(
                                                                  label:
                                                                      Text(s),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue
                                                                          .shade50,
                                                                  labelStyle:
                                                                      const TextStyle(
                                                                          color:
                                                                              Color(0xFF1976D2))))
                                                              .toList(),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (appliedTeams.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.groups, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Applied Teams',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: appliedTeams.map<Widget>((team) {
                                    if (team is! Map)
                                      return const SizedBox.shrink();
                                    final teamName = team['teamName'] ??
                                        team['name'] ??
                                        'Unknown Team';
                                    final teamId = team['teamId'] as String?;
                                    final members =
                                        (team['members'] as List?) ?? [];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.groups,
                                                    color: Color(0xFF1976D2)),
                                                const SizedBox(width: 8),
                                                Text(teamName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16)),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            if (members.isNotEmpty)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Members:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.black87)),
                                                  const SizedBox(height: 6),
                                                  ...members
                                                      .map<Widget>((member) {
                                                    if (member is! Map)
                                                      return const SizedBox
                                                          .shrink();
                                                    final memberName =
                                                        member['fullName'] ??
                                                            member['name'] ??
                                                            'Unknown';
                                                    final memberSkills =
                                                        (member['skills']
                                                                    as List?)
                                                                ?.cast<
                                                                    String>() ??
                                                            [];
                                                    final memberId =
                                                        member['userId']
                                                            as String?;
                                                    return FutureBuilder<
                                                        DocumentSnapshot>(
                                                      future: memberId != null
                                                          ? FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(memberId)
                                                              .get()
                                                          : null,
                                                      builder: (context,
                                                          memberSnapshot) {
                                                        String?
                                                            memberProfileImage;
                                                        if (memberSnapshot
                                                                .hasData &&
                                                            memberSnapshot
                                                                .data!.exists) {
                                                          final memberData =
                                                              memberSnapshot
                                                                      .data!
                                                                      .data()
                                                                  as Map<String,
                                                                      dynamic>;
                                                          memberProfileImage =
                                                              memberData[
                                                                      'profileImage']
                                                                  as String?;
                                                        }
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 6),
                                                          child: Row(
                                                            children: [
                                                              memberProfileImage !=
                                                                          null &&
                                                                      memberProfileImage
                                                                          .isNotEmpty
                                                                  ? CircleAvatar(
                                                                      backgroundImage:
                                                                          NetworkImage(
                                                                              memberProfileImage),
                                                                      radius:
                                                                          18,
                                                                    )
                                                                  : CircleAvatar(
                                                                      backgroundColor:
                                                                          const Color(
                                                                              0xFF1976D2),
                                                                      radius:
                                                                          18,
                                                                      child:
                                                                          Text(
                                                                        memberName.isNotEmpty
                                                                            ? memberName[0]
                                                                            : '?',
                                                                        style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontWeight: FontWeight.bold),
                                                                      ),
                                                                    ),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                        memberName,
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold)),
                                                                    if (memberSkills
                                                                        .isNotEmpty)
                                                                      Wrap(
                                                                        spacing:
                                                                            6,
                                                                        children: memberSkills
                                                                            .map((s) => Chip(
                                                                                label: Text(s),
                                                                                backgroundColor: Colors.blue.shade50,
                                                                                labelStyle: const TextStyle(color: Color(0xFF1976D2))))
                                                                            .toList(),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }).toList(),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
