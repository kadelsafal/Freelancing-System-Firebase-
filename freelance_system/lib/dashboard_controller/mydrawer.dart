import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_system/screens/profile.dart';
import 'package:freelance_system/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/userProvider.dart';

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool isToggleOn = false;

  @override
  void initState() {
    super.initState();
    _loadToggleState(); // Load the saved toggle state when the drawer is created
  }

  // Load the toggle state from SharedPreferences
  Future<void> _loadToggleState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isToggleOn = prefs.getBool('isFreelancing') ?? false;
    });
  }

  // Save the toggle state to SharedPreferences
  Future<void> _saveToggleState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFreelancing', value);
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

  // Method to handle the mode toggle and force refresh
  void _handleToggle(bool value) async {
    setState(() {
      isToggleOn = value;
    });

    // Save the toggle state in SharedPreferences
    await _saveToggleState(value);

    // Restart the app to apply the changes
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
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
            child: Container(
              height: 300, // Increase the height of the header as required
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Text(
                      userProvider.userName.isNotEmpty
                          ? userProvider.userName[0].toUpperCase()
                          : "U",
                      style: TextStyle(
                          fontSize: 48,
                          color: const Color.fromARGB(255, 255, 255, 255)),
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 192, 2),
                  ),
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
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: Colors.blue),
                  title: Text(
                    "Profile",
                    style: TextStyle(fontSize: 20),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    "Logout",
                    style: TextStyle(fontSize: 20),
                  ),
                  onTap: () {
                    _handleLogout(context);
                  },
                ),
              ],
            ),
          ),

          // Switch at the Bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                Text(
                  "Toggle Option",
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: isToggleOn,
                  onChanged: (value) {
                    _handleToggle(
                        value); // Handle the toggle and refresh the app
                  },
                  activeColor: Colors.blue,
                  inactiveThumbColor: Colors.grey,
                ),
                // Display the mode beside the switch
                Text(
                  isToggleOn ? 'Freelancing Mode' : 'Client Mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: isToggleOn ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
