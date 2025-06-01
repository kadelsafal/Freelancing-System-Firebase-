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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
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
                radius: 20,
                backgroundColor: const Color(0xFF1976D2),
                child: Text(
                  widget.teamName.isNotEmpty
                      ? widget.teamName[0].toUpperCase()
                      : "?",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.teamName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                  );
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
                                    padding: const EdgeInsets.all(8),
                                    child: FutureBuilder<Map<String, dynamic>>(
                                      future:
                                          UserService.getUserProfile(senderId),
                                      builder: (context, userSnapshot) {
                                        final userData =
                                            userSnapshot.data ?? {};
                                        final profileImage =
                                            userData['profileImage'];
                                        final seenByInitial =
                                            senderName.isNotEmpty
                                                ? senderName[0].toUpperCase()
                                                : '?';

                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              const Color(0xFF1976D2),
                                          backgroundImage:
                                              (profileImage != null &&
                                                      profileImage.isNotEmpty)
                                                  ? NetworkImage(profileImage)
                                                  : null,
                                          child: (profileImage == null ||
                                                  profileImage.isEmpty)
                                              ? Text(seenByInitial,
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white))
                                              : null,
                                        );
                                      },
                                    )),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? const Color(0xFF1976D2)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message['text'] ?? '',
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Seen",
                                      style: TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ...seenAvatarsToShow.map((userId) {
                                      return FutureBuilder<Map<String, String>>(
                                        future:
                                            TeamService.getUserInfoById(userId),
                                        builder: (context, snapshot) {
                                          final data = snapshot.data;
                                          final name = data?['name'] ?? 'U';
                                          final profileImage =
                                              data?['profileImage'] ?? '';
                                          final initial = name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?';

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4.0),
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundImage: (profileImage
                                                      .isNotEmpty)
                                                  ? NetworkImage(profileImage)
                                                  : null,
                                              backgroundColor:
                                                  profileImage.isEmpty
                                                      ? const Color(0xFF1976D2)
                                                      : Colors.transparent,
                                              child: profileImage.isEmpty
                                                  ? Text(
                                                      initial,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white),
                                                    )
                                                  : null,
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ],
                                ),
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
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      final message = _messageController.text.trim();
                      if (message.isNotEmpty) {
                        final senderId = currentUser?.uid;

                        String senderName = "User";
                        if (senderId != null && senderId.isNotEmpty) {
                          final profile =
                              await UserService.getUserProfile(senderId);
                          senderName = profile?['Full Name'] ??
                              profile?['fullName'] ??
                              profile?['name'] ??
                              "User";
                        }

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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(30),
                      ),
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
}
