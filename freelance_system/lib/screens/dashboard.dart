import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/chats/chat_page.dart';
import 'package:freelance_system/dashboard_controller/Mypost.dart';
import 'package:freelance_system/dashboard_controller/mydrawer.dart';
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

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
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
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_active_outlined,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ChatPage()));
                },
                icon: const Icon(
                  Icons.telegram,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          toolbarHeight: 90,
        ),
        drawer: Drawer(
          child: Container(
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
                    labelText: "Search here",
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          searchQuery =
                              searchController.text.trim().toLowerCase();
                        });
                      },
                      icon: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 0, 134),
                          borderRadius: BorderRadius.circular(20.0),
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
              if (searchQuery.isEmpty) MyPost(userId: userProvider.userId),
            ],
          ),
        ),
      ),
    );
  }
}
