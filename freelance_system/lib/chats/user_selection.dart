import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'package:freelance_system/chats/user_service.dart';

void showTeamCreationDialog(
    BuildContext context, VoidCallback refreshTeams, String _userId) {
  final TextEditingController teamNameController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: UserService.fetchMutualFollowers(_userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text("Error: ${snapshot.error}")),
              );
            }
            final users = snapshot.data ?? [];
            return _buildTeamCreationForm(
                context, users, refreshTeams, teamNameController);
          },
        ),
      );
    },
  );
}

Widget _buildTeamCreationForm(
    BuildContext context,
    List<Map<String, dynamic>> users,
    VoidCallback refreshTeams,
    TextEditingController teamNameController) {
  return StatefulBuilder(
    builder: (context, setState) {
      List<String> selectedUserIds = [];
      String? selectedAdminId;

      return Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create a New Team",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Team Name Input
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Admin Selection Dropdown
            Text("Select Team Admin:",
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Choose an Admin',
              ),
              hint: const Text('Select Team Admin'),
              value: selectedAdminId,
              items: users.map((user) {
                String userId = user["id"];
                String userName = user["Full Name"] ??
                    user["name"] ??
                    user["displayName"] ??
                    "User";
                return DropdownMenuItem(value: userId, child: Text(userName));
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedAdminId = value;
                  if (value != null && !selectedUserIds.contains(value)) {
                    selectedUserIds.add(value);
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // Member Selection List
            Text("Select Team Members (min 3):",
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            users.isEmpty
                ? const Center(child: Text("No users available"))
                : SizedBox(
                    height: 250, // Fixed height for better scroll control
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        String userId = users[index]["id"];
                        String userName = users[index]["Full Name"] ??
                            users[index]["name"] ??
                            "User";

                        bool isAdmin = userId == selectedAdminId;

                        return CheckboxListTile(
                          title: Text(userName),
                          subtitle: isAdmin
                              ? const Text("Team Admin",
                                  style: TextStyle(color: Colors.blue))
                              : null,
                          value: selectedUserIds.contains(userId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedUserIds.add(userId);
                              } else {
                                if (!isAdmin) {
                                  selectedUserIds.remove(userId);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),

            // Create Team Button
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  String teamName = teamNameController.text.trim();

                  if (teamName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a team name")),
                    );
                    return;
                  }

                  if (selectedUserIds.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select at least 3 members")),
                    );
                    return;
                  }

                  if (selectedAdminId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select a team admin")),
                    );
                    return;
                  }

                  TeamService.createTeam(
                    teamName: teamName,
                    adminId: selectedAdminId!,
                    memberIds: selectedUserIds,
                  );

                  Navigator.pop(context);
                  refreshTeams();
                },
                child: const Text("Create Team"),
              ),
            ),
          ],
        ),
      );
    },
  );
}
