import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  late Stream<QuerySnapshot> notificationsStream;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> handleFollowBack(String fromUserId, String fromUserName) async {
    final db = FirebaseFirestore.instance;

    try {
      // Add to current user's following
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(fromUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'fullName': fromUserName,
      });

      // Add to from user's followers
      final currentUserDoc =
          await db.collection('users').doc(currentUserId).get();
      final currentUserName = currentUserDoc['Full Name'] ?? '';

      await db
          .collection('users')
          .doc(fromUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'fullName': currentUserName,
      });

      // Update follow counts
      await db.collection('users').doc(currentUserId).update({
        'followed': FieldValue.increment(1),
      });
      await db.collection('users').doc(fromUserId).update({
        'followers': FieldValue.increment(1),
      });

      // 🔔 Create a follow-back notification for the other user
      await db
          .collection('users')
          .doc(fromUserId)
          .collection('notifications')
          .add({
        'type': 'follow',
        'fromUserId': currentUserId,
        'fromUserName': currentUserName,
        'message': '$currentUserName followed you back',
        'seen': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the UI immediately
      setState(() {
        // Refresh the notifications stream
        notificationsStream = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You followed back $fromUserName')),
      );
    } catch (e) {
      print("Error in follow back: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow back')),
      );
    }
  }

  Future<bool> checkIfFollowing(String otherUserId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(otherUserId)
        .get();
    return doc.exists;
  }

  String formatTimestamp(Timestamp timestamp) {
    // Format the timestamp into a human-readable format
    return DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: Container(
        color: const Color(0xFFF4F8FB),
        child: StreamBuilder<QuerySnapshot>(
          stream: notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading notifications."));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return const Center(child: Text("No notifications yet."));
            }

            return Column(
              children: [
                // Project Deadline Reminder Banner
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .where('status', isEqualTo: 'Pending')
                      .snapshots(),
                  builder: (context, projectSnapshot) {
                    if (!projectSnapshot.hasData) {
                      return SizedBox.shrink();
                    }

                    final projects = projectSnapshot.data!.docs;
                    List<Map<String, dynamic>> deadlineProjects = [];

                    for (var project in projects) {
                      final data = project.data() as Map<String, dynamic>;
                      final deadline = data['deadline'] as String?;
                      final title = data['title'] as String?;
                      final appointedFreelancer =
                          data['appointedFreelancer'] as String?;
                      final appointedTeamId =
                          data['appointedTeamId'] as String?;
                      final appliedTeams =
                          data['appliedTeams'] as List<dynamic>?;

                      print("Checking project: $title");
                      print("Deadline: $deadline");
                      print("Appointed Freelancer: $appointedFreelancer");
                      print("Current User ID: $currentUserId");

                      if (deadline != null && title != null) {
                        try {
                          final deadlineDate = DateTime.parse(deadline);
                          final now = DateTime.now();
                          // Set both dates to midnight for accurate day comparison
                          final deadlineMidnight = DateTime(deadlineDate.year,
                              deadlineDate.month, deadlineDate.day);
                          final nowMidnight =
                              DateTime(now.year, now.month, now.day);

                          final remainingDays =
                              deadlineMidnight.difference(nowMidnight).inDays;
                          print("Remaining days: $remainingDays");

                          // Check if user is appointed or part of appointed team
                          bool isUserAppointed = false;

                          // Check if user is appointed as freelancer
                          if (appointedFreelancer == currentUserId) {
                            isUserAppointed = true;
                            print("User is appointed as freelancer");
                          }
                          // Check if user is part of appointed team
                          else if (appointedTeamId != null &&
                              appliedTeams != null) {
                            print("Checking team appointments");
                            for (var team in appliedTeams) {
                              if (team != null &&
                                  team is Map<String, dynamic>) {
                                if (team['teamId'] == appointedTeamId) {
                                  List<dynamic> members = team['members'] ?? [];
                                  isUserAppointed = members.any((member) =>
                                      member is Map<String, dynamic> &&
                                      member['userId'] == currentUserId);
                                  if (isUserAppointed) {
                                    print("User is part of appointed team");
                                  }
                                  break;
                                }
                              }
                            }
                          }

                          print("Is user appointed: $isUserAppointed");

                          // Show reminder if user is appointed and deadline is today or within 7 days
                          if (isUserAppointed &&
                              remainingDays >= 0 &&
                              remainingDays <= 7) {
                            String deadlineText = remainingDays == 0
                                ? "Due today"
                                : remainingDays == 1
                                    ? "Due tomorrow"
                                    : "$remainingDays days remaining";

                            print(
                                "Adding project to deadline list: $title - $deadlineText");

                            deadlineProjects.add({
                              'title': title,
                              'remainingDays': remainingDays,
                              'deadline': deadline,
                              'deadlineText': deadlineText,
                            });
                          }
                        } catch (e) {
                          print("Error parsing deadline: $e");
                        }
                      }
                    }

                    print(
                        "Total deadline projects: ${deadlineProjects.length}");

                    if (deadlineProjects.isEmpty) {
                      print("No deadline projects to display");
                      return SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Project Deadline Reminders",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...deadlineProjects
                              .map((project) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          color: Colors.red.shade700,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "${project['title']} - ${project['deadlineText']}",
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final type = notif['type'];
                      final fromUserId = notif['fromUserId'];
                      final fromUserName = notif['fromUserName'];
                      final message = notif['message'];
                      final seen = notif['seen'] ?? false;
                      final timestamp = notif['timestamp'] as Timestamp;

                      return FutureBuilder<bool>(
                        future: checkIfFollowing(fromUserId),
                        builder: (context, snapshot) {
                          final isFollowing = snapshot.data ?? false;

                          return Dismissible(
                            key: Key(notif.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              await notif.reference.delete();
                            },
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF1976D2),
                                    child: const Icon(Icons.notifications,
                                        color: Colors.white),
                                  ),
                                  if (!seen)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF1976D2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                message ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(type),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimestamp(timestamp),
                                    style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: type == "follow"
                                  ? isFollowing
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF1976D2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "Following",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: () => handleFollowBack(
                                              fromUserId, fromUserName),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1976D2),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            "Follow Back",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        )
                                  : null,
                              tileColor: !seen
                                  ? Colors.lightBlue.withOpacity(0.1)
                                  : Colors.white,
                              onTap: () async {
                                // Mark notification as seen
                                await notif.reference.update({"seen": true});
                                // Update the UI immediately
                                setState(() {
                                  // Refresh the notifications stream
                                  notificationsStream = FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .doc(currentUserId)
                                      .collection('notifications')
                                      .orderBy('timestamp', descending: true)
                                      .snapshots();
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
