// team_creation_dialog.dart (modified with avatars and mutual followers)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/chats/team_service.dart';
import 'package:freelance_system/chats/user_service.dart';

void showTeamCreationDialog(
    BuildContext context, String currentUserId, VoidCallback refreshTeams) {
  final TextEditingController teamNameController = TextEditingController();
  String? selectedAdminId =
      currentUserId; // Set the current user's ID as the default admin

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: (() async {
            final currentUser = FirebaseAuth.instance.currentUser;
            List<Map<String, dynamic>> users =
                await UserService.fetchMutualFollowers(currentUserId);

            if (currentUser != null &&
                !users.any((user) => user['id'] == currentUser.uid)) {
              String? fullName =
                  await UserService.getUserFullName(currentUser.uid);
              users.add({
                "id": currentUser.uid,
                "Full Name": fullName ?? "You",
              });
            }

            return users;
          })(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("Error: ${snapshot.error}")),
              );
            }

            final users = snapshot.data ?? [];

            return Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create a New Team",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      hintText: 'Enter team name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Select Team Members (min 3):",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8),
                  users.isEmpty
                      ? Center(child: Text("No mutual connections available"))
                      : Flexible(
                          child: _buildUserSelection(
                              users,
                              context,
                              refreshTeams,
                              teamNameController,
                              selectedAdminId),
                        ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildUserSelection(
    List<Map<String, dynamic>> users,
    BuildContext context,
    VoidCallback refreshTeams,
    TextEditingController teamNameController,
    String? selectedAdminId) {
  List<String> selectedUserIds = [
    selectedAdminId!
  ]; // Ensure the current user is in the list

  return StatefulBuilder(
    builder: (context, setState) {
      return Container(
        width: double.maxFinite,
        height: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Admin selection dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Team Admin',
                border: OutlineInputBorder(),
              ),
              hint: Text(
                'Choose an admin for this team',
                style: TextStyle(fontSize: 14),
              ),
              value: selectedAdminId,
              items: users.map((user) {
                String userId = user["id"];
                String fullName = user["Full Name"] ??
                    user["fullName"] ??
                    user["displayName"] ??
                    "User";

                return DropdownMenuItem<String>(
                  value: userId,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 12,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(fullName),
                    ],
                  ),
                );
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
            SizedBox(height: 12),

            // Member selection list
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  String userId = users[index]["id"];
                  String fullName = users[index]["Full Name"] ??
                      users[index]["fullName"] ??
                      users[index]["displayName"] ??
                      "User";

                  bool isAdmin = userId == selectedAdminId;

                  return CheckboxListTile(
                    secondary: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(fullName),
                    subtitle: isAdmin
                        ? Text("Team Admin",
                            style: TextStyle(color: Colors.blue))
                        : null,
                    value: selectedUserIds.contains(userId),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedUserIds.add(userId);
                        } else {
                          if (isAdmin) {
                            return;
                          }
                          selectedUserIds.remove(userId);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Create team button
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  String teamName = teamNameController.text.trim();

                  if (teamName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a team name")));
                    return;
                  }

                  if (selectedUserIds.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Please select at least 3 members")));
                    return;
                  }

                  if (selectedAdminId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please select a team admin")));
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
