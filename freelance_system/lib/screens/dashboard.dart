import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/chat_page.dart';
import 'package:freelance_system/dashboard_controller/post.dart';
import 'package:freelance_system/dashboard_controller/mydrawer.dart';
import 'package:freelance_system/dashboard_controller/notifications.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard_controller/profilepage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:freelance_system/chats/chat_service.dart';
import 'package:freelance_system/chats/team_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
  }

  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
// Function to mark notifications as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final db = FirebaseFirestore.instance;

    try {
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true, // Mark the notification as read
      });
      print("Notification marked as read.");
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _unfocusKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);

    return GestureDetector(
      onTap: () => _unfocusKeyboard(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          title: const Text(
            "QuickLance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xFF1976D2),
              letterSpacing: 1.2,
              fontFamily: 'Montserrat',
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Notifications()),
                      );
                    },
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                          color: Color(0xFF1976D2),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('notifications')
                              .where('seen', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              return Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    snapshot.data!.docs.length.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    tooltip: 'Notifications',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatPage()),
                      );
                    },
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.chat_outlined,
                          size: 28,
                          color: Color(0xFF1976D2),
                        ),
                        StreamBuilder<int>(
                          stream: Rx.combineLatest2(
                            ChatService.getUnseenChatsCountStream(
                                currentUserId),
                            TeamService.getUnseenMessagesCountStream(
                                currentUserId),
                            (int chatCount, int teamCount) =>
                                chatCount + teamCount,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              return Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    snapshot.data!.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    tooltip: 'Chat',
                  ),
                ],
              ),
            ),
          ],
          foregroundColor: Color(0xFF1976D2),
          toolbarHeight: 80,
        ),
        body: Container(
          color: const Color(0xFFF4F8FB),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 16.0),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(30.0),
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          setState(() {
                            searchQuery = value.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search projects or clients",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 22),
                          isDense: true,
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF1976D2), size: 22),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey.shade600, size: 20),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(
                                color: Color(0xFF1976D2), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (searchQuery.isNotEmpty)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No users found."));
                        }

                        // Filter results dynamically for case-insensitive match and excluding current user
                        var users = snapshot.data!.docs.where((userDoc) {
                          String fullName = (userDoc.data()
                                      as Map<String, dynamic>)['Full Name']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';

                          String uid =
                              userDoc['id'] ?? userDoc.id; // fallback to doc.id
                          return fullName.contains(searchQuery.toLowerCase()) &&
                              uid != currentUserId;
                        }).toList();

                        if (users.isEmpty) {
                          return const Center(child: Text("No users found."));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var userDoc = users[index];
                            String userId = userDoc.id;
                            String userName = userDoc['Full Name'] ?? '';
                            String userImage =
                                userDoc['profile_image']?.isEmpty ?? true
                                    ? ''
                                    : userDoc['profile_image'];
                            String userIcon = userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?';

                            return ListTile(
                              leading: userImage.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(userImage),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Color(0xFF1976D2),
                                      child: Text(
                                        userIcon,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                              title: Text(userName),
                              onTap: () {
                                // Clear the search query and text field first
                                setState(() {
                                  searchQuery =
                                      ''; // Explicitly reset searchQuery to trigger a rebuild
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Profilepage(
                                      userId: userId,
                                      userName: userName,
                                      userImage: userImage,
                                    ),
                                  ),
                                );

                                searchController.clear();
                              },
                            );
                          },
                        );
                      },
                    ),
                  if (searchQuery.isEmpty) Post(userId: userProvider.userId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
