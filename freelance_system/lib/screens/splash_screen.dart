import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:freelance_system/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isFreelancing = false;

  @override
  void initState() {
    super.initState();
    _loadToggleState();
    Future.delayed(const Duration(seconds: 2), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        openLogin();
      } else {
        await Provider.of<Userprovider>(context, listen: false)
            .getUserDetails();
        openDashboard();
      }
    });
  }

  Future<void> _loadToggleState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFreelancing = prefs.getBool('isFreelancing') ?? false;
    });
  }

  void openDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationMenu(
          initialIndex: 0,
        ),
      ),
    );
  }

  void openLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/Quicklance Logo.png', // <-- path to your logo asset
          width: 350, // adjust width as needed
          height: 400, // adjust height as needed
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
