import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_chat_screen.dart';
import 'package:intl/intl.dart';

class TeamList extends StatelessWidget {
  final List<Map<String, dynamic>> teams;

  const TeamList({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // fallback to passed `teams` if no data available yet
        final teamDocs = snapshot.hasData
            ? snapshot.data!.docs
            : teams.map((team) => FakeDocument(team)).toList();

        return ListView.builder(
          itemCount: teamDocs.length,
          itemBuilder: (context, index) {
            final doc = teamDocs[index];
            final data = doc is FakeDocument
                ? doc.data
                : (doc as QueryDocumentSnapshot).data() as Map<String, dynamic>;

            final teamName = data["teamName"] ?? "Unnamed Team";
            final lastMessage = data["lastMessage"] ?? "";
            final timestamp = data["lastMessageTime"] as Timestamp?;
            final teamId = data["id"] ?? (doc as QueryDocumentSnapshot).id;

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

            return Card(
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
            );
          },
        );
      },
    );
  }
}

// Fallback class for local list of teams if no Firestore snapshot yet
class FakeDocument {
  final Map<String, dynamic> data;
  FakeDocument(this.data);
}
