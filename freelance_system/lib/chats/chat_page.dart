import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/chat_service.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'chat_tab.dart';
import 'team_tab.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late Stream<int> _unseenMessageCountStream;
  late Stream<int> _unseenChatCountStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _unseenChatCountStream = ChatService.getUnseenChatsCountStream(userId);
      _unseenMessageCountStream =
          TeamService.getUnseenMessagesCountStream(userId);

      print("user id, $userId");
    } else {
      _unseenChatCountStream = Stream.value(0);
      _unseenMessageCountStream = Stream.value(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            StreamBuilder<int>(
              stream: _unseenChatCountStream,
              builder: (context, snapshot) {
                int count = snapshot.data ?? 0;
                print(
                    "Unseen chat count in builder: $count"); // Log the unseen chat count
                return _buildTabWithBadge("Chats", count);
              },
            ),
            StreamBuilder<int>(
              stream: _unseenMessageCountStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Tab(
                    text: "Team Building",
                  );
                }

                int unseenMessageCount = snapshot.data ?? 0;
                print(
                    "Unseen message count in builder: $unseenMessageCount"); // Log in the builder

                return Stack(
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text("Team Building"),
                    ),
                    if (unseenMessageCount > 0)
                      Positioned(
                        right: 10,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$unseenMessageCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatTab(),
          TeamTab(),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String label, int count) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(label),
        ),
        if (count > 0)
          Positioned(
            right: 10,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
