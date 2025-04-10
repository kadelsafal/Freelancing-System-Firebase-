import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_chat_screen.dart';
import 'package:intl/intl.dart';

class TeamList extends StatelessWidget {
  final List<Map<String, dynamic>> teams;

  const TeamList({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('members',
              arrayContains:
                  currentUserId) // Filter teams where user is a member
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Only use the snapshot data if available; otherwise, fall back to local list
        final teamDocs = snapshot.hasData
            ? snapshot.data!.docs
            : []; // Ensure no teams are added when there is no snapshot data

        return ListView.builder(
          itemCount: teamDocs.length,
          itemBuilder: (context, index) {
            final doc = teamDocs[index];
            final data = doc.data() as Map<String, dynamic>;

            final teamName = data["teamName"] ?? "Unnamed Team";
            final lastMessage = data["lastMessage"] ?? "";
            final timestamp = data["lastMessageTime"] as Timestamp?;
            final teamId = data["id"] ?? doc.id;

            String timeString = "";
            if (timestamp != null) {
              final dateTime = timestamp.toDate();
              final now = DateTime.now();

              if (dateTime.year == now.year &&
                  dateTime.month == now.month &&
                  dateTime.day == now.day) {
                timeString = DateFormat('h:mm a').format(dateTime);
              } else if (dateTime.year == now.year) {
                timeString = DateFormat('MMM d').format(dateTime);
              } else {
                timeString = DateFormat('MM/dd/yy').format(dateTime);
              }
            }

            return Dismissible(
              key: Key(teamId), // Unique key for each item
              direction:
                  DismissDirection.endToStart, // Swipe from right to left
              onDismissed: (direction) async {
                // Delete team from Firestore
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(teamId)
                    .delete();
                // Optionally, show a snackbar or a confirmation message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$teamName deleted')),
                );
              },
              background: Container(
                color: Colors.red, // Red background to indicate delete action
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white), // Delete icon
              ),
              child: Card(
                elevation: 1,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      teamName.isNotEmpty ? teamName[0].toUpperCase() : "?",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    teamName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lastMessage.isEmpty ? "No messages yet" : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamChatScreen(
                          teamId: teamId,
                          teamName: teamName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
