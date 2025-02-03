import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_system/navigation_bar.dart';
import 'package:freelance_system/screens/dashboard.dart';
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

  var user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadToggleState();
    Future.delayed(Duration(seconds: 2), () {
      if (user == null) {
        openLogin();
      } else {
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

  void _toggleMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFreelancing = !isFreelancing;
      prefs.setBool('isFreelancing', isFreelancing);
    });
  }

  void openDashboard() {
    Provider.of<Userprovider>(context, listen: false).getUserDetails();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationMenu(),
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
      body: Center(
        child: Text("Swatantra Pesa",
            style: TextStyle(
              fontSize: 25.0,
            )),
      ),
    );
  }
}
