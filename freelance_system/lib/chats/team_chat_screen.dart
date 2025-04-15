import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/team_info.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'package:freelance_system/chats/user_service.dart';
import 'package:intl/intl.dart';

class TeamChatScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamChatScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  @override
  _TeamChatScreenState createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? teamDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    try {
      final details = await TeamService.getTeamDetails(widget.teamId);
      if (mounted) {
        setState(() {
          teamDetails = details;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading team details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamInfoScreen(
                  teamId: widget.teamId,
                  teamName: widget.teamName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorDark,
                child: Text(
                  widget.teamName.isNotEmpty
                      ? widget.teamName[0].toUpperCase()
                      : "?",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text(widget.teamName),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: TeamService.getTeamMessages(widget.teamId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                TeamService.markMessagesAsSeen(snapshot.data!, currentUserId);

                if (messages.isEmpty) {
                  return Center(
                      child: Text('No messages yet. Start the conversation!'));
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                // 1. Map each seen user (excluding current user) to their last seen message index
                Map<String, int> lastSeenByUser = {};
                for (int i = 0; i < messages.length; i++) {
                  final msg = messages[i].data() as Map<String, dynamic>;
                  final seenBy = List<String>.from(msg['isSeenBy'] ?? []);
                  final senderId = msg['sender'];

                  for (String uid in seenBy) {
                    if (uid != senderId) {
                      lastSeenByUser[uid] =
                          i; // keep updating to get their latest seen message
                    }
                  }
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = message['sender'] == currentUser?.uid;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final senderName = message['senderName'] ?? 'Unknown User';
                    final senderId = message['sender'];
                    final isSeenBy =
                        List<String>.from(message['isSeenBy'] ?? []);

                    String timeString = "";
                    if (timestamp != null) {
                      final dateTime = timestamp.toDate();
                      timeString = DateFormat('h:mm a').format(dateTime);
                    }

                    List<String> seenAvatarsToShow = [];
                    for (String userId in isSeenBy) {
                      if (userId != senderId &&
                          userId != currentUserId &&
                          lastSeenByUser[userId] == index) {
                        seenAvatarsToShow.add(userId);
                      }
                    }

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isCurrentUser)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4.0, left: 4.0),
                              child: Text(
                                senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: isCurrentUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!isCurrentUser)
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircleAvatar(
                                    radius: 20,
                                    child: Text(senderName[0],
                                        style: TextStyle(fontSize: 28)),
                                  ),
                                ),
                              Container(
                                padding: EdgeInsets.all(12),
                                margin: EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[200]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(message['text'] ?? ''),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          if (timeString.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 2.0, left: 4.0, right: 4.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          if (seenAvatarsToShow.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: seenAvatarsToShow.map((userId) {
                                  return FutureBuilder<String>(
                                    future: TeamService.getUserNameById(userId),
                                    builder: (context, snapshot) {
                                      final name = snapshot.data ?? 'U';
                                      final initial = name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?';

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.grey[400],
                                          child: Text(
                                            initial,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      final message = _messageController.text.trim();
                      if (message.isNotEmpty) {
                        final senderId = currentUser?.uid;
                        // Fetch full name from Firestore instead of FirebaseAuth displayName
                        final senderName =
                            await UserService.getUserFullName(senderId ?? '') ??
                                "User";
                        await TeamService.sendMessage(
                          widget.teamId,
                          message,
                          senderId: senderId,
                          senderName: senderName,
                        );
                        _messageController.clear();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // void _showTeamInfo(BuildContext context) async {
  //   if (teamDetails == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Team details are still loading...")),
  //     );
  //     return;
  //   }

  //   List<String> teamMemberIds =
  //       List<String>.from(teamDetails?['members'] ?? []);
  //   String adminId = teamDetails?['admin'] ?? '';

  //   // 🔹 Fetch member details from Firestore concurrently
  //   List<Future<Map<String, dynamic>>> memberFutures =
  //       teamMemberIds.map((memberId) {
  //     return FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(memberId)
  //         .get()
  //         .then((userDoc) {
  //       if (userDoc.exists) {
  //         Map<String, dynamic> userData =
  //             userDoc.data() as Map<String, dynamic>;
  //         return {
  //           'id': memberId,
  //           'fullName': userData['Full Name'] ?? "Unknown User"
  //         };
  //       } else {
  //         return {'id': memberId, 'fullName': "Unknown User"};
  //       }
  //     });
  //   }).toList();

  //   // Wait for all member fetches to complete
  //   List<Map<String, dynamic>> members = await Future.wait(memberFutures);

  //   // 🔹 Show Bottom Sheet after fetching names
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         height:
  //             MediaQuery.of(context).size.height * 0.6, // Make it scrollable
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 50,
  //                 height: 5,
  //                 margin: EdgeInsets.only(bottom: 16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[300],
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               "Team Members",
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: members.length,
  //                 itemBuilder: (context, index) {
  //                   final member = members[index];
  //                   final isAdmin = member['id'] == adminId;
  //                   final fullName = member['fullName'];

  //                   return ListTile(
  //                     leading: CircleAvatar(
  //                       backgroundColor: isAdmin
  //                           ? Theme.of(context).primaryColor
  //                           : Colors.grey[400],
  //                       child: Text(
  //                         fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
  //                         style: TextStyle(color: Colors.white),
  //                       ),
  //                     ),
  //                     title: Text(fullName),
  //                     subtitle: isAdmin
  //                         ? Text(
  //                             "Admin",
  //                             style: TextStyle(
  //                                 color: Theme.of(context).primaryColor),
  //                           )
  //                         : null,
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
}
