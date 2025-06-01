import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_chat_screen.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'package:intl/intl.dart';

class TeamList extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  TeamList({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .where('members',
                arrayContains:
                    currentUserId) // Filter teams where user is a member
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading and error states
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No teams found.'));
          }

          // Mark messages as seen after data has been received

          final teamDocs = snapshot.data!.docs;

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

              return StreamBuilder<bool>(
                stream: TeamService.isLastMessageUnseen(teamId, currentUserId),
                builder: (context, unseenSnapshot) {
                  final isUnseen = unseenSnapshot.data ?? false;

                  return Builder(builder: (safeContext) {
                    return Dismissible(
                      key: Key(teamId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await FirebaseFirestore.instance
                            .collection('teams')
                            .doc(teamId)
                            .delete();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('$teamName deleted')),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isUnseen ? const Color(0xFFE3F0FB) : Colors.white,
                          border: isUnseen
                              ? Border(
                                  left: BorderSide(
                                      color: Color(0xFF1976D2), width: 5))
                              : null,
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1976D2),
                                child: Text(
                                  teamName.isNotEmpty
                                      ? teamName[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isUnseen)
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
                            teamName,
                            style: TextStyle(
                              fontWeight: isUnseen
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isUnseen ? Color(0xFF1976D2) : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            lastMessage.isEmpty
                                ? "No messages yet"
                                : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnseen
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isUnseen ? Color(0xFF1976D2) : Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnseen
                                  ? Color(0xFF1976D2)
                                  : Colors.grey[600],
                              fontWeight: isUnseen
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
