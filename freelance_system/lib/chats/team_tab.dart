import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_creation_dialogue.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'package:freelance_system/chats/team_list.dart';

class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  late Future<List<Map<String, dynamic>>> _teamsFuture;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _teamsFuture = TeamService.fetchUserTeams();
  }

  void _refreshTeams() {
    setState(() {
      _teamsFuture = TeamService.fetchUserTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        // Use FutureBuilder to load teams
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final teams = snapshot.data ?? [];

          return teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("No teams available"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => showTeamCreationDialog(
                            context, currentUserId, _refreshTeams),
                        child: const Text("Build a Team"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => showTeamCreationDialog(
                          context, currentUserId, _refreshTeams),
                      child: const Text("Add a Team"),
                    ),
                    Expanded(
                      child: TeamList(
                          teams: teams), // Pass the filtered teams here
                    ),
                  ],
                );
        },
      ),
    );
  }
}
