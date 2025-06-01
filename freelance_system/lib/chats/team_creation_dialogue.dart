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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: (() async {
            final currentUser = FirebaseAuth.instance.currentUser;
            List<Map<String, dynamic>> users =
                await UserService.fetchMutualFollowers(currentUserId);

            if (currentUser != null &&
                !users.any((user) => user['id'] == currentUser.uid)) {
              final profile = await UserService.getUserProfile(currentUser.uid);
              String? fullName = profile?['Full Name'] ??
                  profile?['fullName'] ??
                  profile?['displayName'];

              users.add({
                "id": currentUser.uid,
                "Full Name": fullName ?? "You",
              });
            }

            return users;
          })(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFF1976D2),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final users = snapshot.data ?? [];

            return Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.group_add, color: Colors.white, size: 32),
                        SizedBox(width: 16),
                        Text(
                          "Create a New Team",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: teamNameController,
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      hintText: 'Enter team name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF1976D2).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1976D2), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF1976D2).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child:
                            const Icon(Icons.group, color: Color(0xFF1976D2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      labelStyle: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.people, color: Color(0xFF1976D2)),
                        SizedBox(width: 12),
                        Text(
                          "Select Team Members (min 3)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  users.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Color(0xFF1976D2)),
                                const SizedBox(width: 12),
                                Text(
                                  "No mutual connections available",
                                  style: TextStyle(
                                    color: const Color(0xFF1976D2)
                                        .withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
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
  List<String> selectedUserIds = [selectedAdminId!];

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1976D2).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Team Admin',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1976D2), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Color(0xFF1976D2)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1976D2)),
              hint: Text(
                'Choose an admin for this team',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              value: selectedAdminId,
              items: users.map((user) {
                String userId = user["id"];
                String fullName = user["Full Name"] ??
                    user["fullName"] ??
                    user["displayName"] ??
                    "User";
                String profileImage = user["profileImage"] ?? "";

                return DropdownMenuItem<String>(
                  value: userId,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1976D2),
                          radius: 16,
                          backgroundImage: (profileImage.isNotEmpty)
                              ? NetworkImage(profileImage)
                              : null,
                          child: (profileImage.isEmpty)
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1976D2).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  String userId = users[index]["id"];
                  String fullName = users[index]["Full Name"] ??
                      users[index]["fullName"] ??
                      users[index]["displayName"] ??
                      "User";
                  String profileImage = users[index]["profileImage"] ?? "";
                  bool isAdmin = userId == selectedAdminId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      secondary: CircleAvatar(
                        backgroundColor: const Color(0xFF1976D2),
                        radius: 16,
                        backgroundImage: (profileImage.isNotEmpty)
                            ? NetworkImage(profileImage)
                            : null,
                        child: (profileImage.isEmpty)
                            ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      subtitle: isAdmin
                          ? Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Team Admin",
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      value: selectedUserIds.contains(userId),
                      activeColor: const Color(0xFF1976D2),
                      checkColor: Colors.white,
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
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (selectedUserIds.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select at least 3 team members"),
                      backgroundColor: Color(0xFF1976D2),
                    ),
                  );
                  return;
                }
                if (selectedAdminId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a team admin"),
                      backgroundColor: Color(0xFF1976D2),
                    ),
                  );
                  return;
                }
                if (teamNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a team name"),
                      backgroundColor: Color(0xFF1976D2),
                    ),
                  );
                  return;
                }

                TeamService.createTeam(
                  teamName: teamNameController.text.trim(),
                  adminId: selectedAdminId!,
                  memberIds: selectedUserIds,
                );
                Navigator.pop(context);
                refreshTeams();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Create Team",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
