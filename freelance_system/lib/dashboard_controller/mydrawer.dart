import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:freelance_system/screens/profile.dart';
import 'package:freelance_system/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import '../providers/userProvider.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool isToggleOn = false;

  @override
  void initState() {
    super.initState();
    // Load the saved toggle state when the drawer is created
  }

  // Method to handle the logout functionality
  void _handleLogout(BuildContext context) {
    // Perform logout logic (e.g., Firebase logout)
    FirebaseAuth.instance.signOut();

    // Navigate to Splash Screen or Login Screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<Userprovider>(context);
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 300, // Increase the height of the header as required
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width:
                          100, // Adjust the width to match the CircleAvatar radius
                      height:
                          100, // Adjust the height to match the CircleAvatar radius
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 148, 148,
                              148), // Border color (adjust to your preference)
                          width: 3, // Border width (adjust as needed)
                        ),
                      ),
                      child: CircleAvatar(
                        radius:
                            60, // This should match the width/height of the container
                        backgroundImage: (userProvider
                                    .profileimage?.isNotEmpty ??
                                false)
                            ? NetworkImage(userProvider.profileimage!)
                            : null, // Display the profile image if available and not empty
                        child: (userProvider.profileimage?.isEmpty ?? true)
                            ? Text(
                                userProvider.userName.isNotEmpty
                                    ? userProvider.userName[
                                        0] // Display the first letter of the user's name
                                    : "?", // If user name is empty, display "?"
                                style: TextStyle(fontSize: 48),
                              )
                            : null, // If there's a profile image, no need to display the initial
                      )),
                  const SizedBox(height: 10),
                  Text(
                    userProvider.userName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "ID: ${userProvider.userId}",
                    style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(179, 0, 0, 0)),
                  ),
                  Text(
                    "Phone: ${userProvider.userphn}",
                    style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(179, 0, 0, 0)),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                  vertical: 10), // Overall spacing for the list
              children: [
                _buildListTile(
                  icon: Icons.person,
                  iconColor: Colors.white,
                  bgColor: Colors.deepPurple,
                  title: "Profile",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  ),
                ),
                SizedBox(height: 15), // Uniform gap between tiles
                // Uniform gap
                _buildListTile(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  bgColor: Colors.transparent, // No background for logout
                  title: "Logout",
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),

          // Switch at the Bottom
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: iconColor, size: 35), // Standardized icon size
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
