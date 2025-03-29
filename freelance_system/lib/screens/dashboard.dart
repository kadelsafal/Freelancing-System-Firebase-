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
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Swatantra Pesa"),
              const Spacer(),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Notifications()),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined,
                        size: 30, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  // Real-time Unread Notifications Count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .collection('notifications')
                        .where('read',
                            isEqualTo: false) // Only unread notifications
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        // If no notifications are found in the subcollection
                        print("No unread notifications found.");
                        return SizedBox.shrink();
                      }

                      int unreadCount = snapshot.data!.docs.length;

                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ChatPage()));
                },
                icon: const Icon(
                  Icons.telegram,
                  size: 40,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          toolbarHeight: 90,
        ),
        drawer: Drawer(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // Adjust the width
            child: MyDrawer(), // Use your custom drawer
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(
                          255, 103, 103, 103), // Set label text color to purple
                    ),
                    labelText: "Search here",
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20), // Adjust padding
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(50.0), // Fully rounded border
                      borderSide: BorderSide(
                          color: Colors.grey), // Optional border color
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 102, 99, 99),
                          width: 2.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2.0), // Highlight color on focus
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          searchQuery =
                              searchController.text.trim().toLowerCase();
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(
                              50.0), // Fully rounded icon button
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.search,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found."));
                    }

                    // Filter results dynamically for case insensitivity
                    var users = snapshot.data!.docs.where((userDoc) {
                      String fullName =
                          userDoc['Full Name'].toString().toLowerCase();
                      return fullName.contains(searchQuery);
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
                        String userName = userDoc['Full Name'];
                        String userIcon = userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?';

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(userIcon),
                          ),
                          title: Text(userName),
                          onTap: () {
                            // Clear the search query and text field first
                            setState(() {
                              searchQuery =
                                  ''; // Explicitly reset searchQuery to trigger a rebuild
                            });
                            searchController.clear();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profilepage(
                                  userId: userId,
                                  userName: userName,
                                ),
                              ),
                            );
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
    );
  }
}
