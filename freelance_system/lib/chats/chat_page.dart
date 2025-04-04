// chat_page.dart
import 'package:flutter/material.dart';
import 'chat_tab.dart';
import 'team_tab.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "Team Building"),
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
}
