import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freelance_system/screens/dashboard.dart';
import 'package:freelance_system/screens/project.dart';
import 'package:freelance_system/screens/profile.dart';
import 'package:freelance_system/screens/payment.dart';
import 'package:freelance_system/screens/elearning.dart';
import 'package:freelance_system/screens/resume.dart';
import 'package:freelance_system/freelancer/FreelancerBoard.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  bool isFreelancing = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFreelancing = prefs.getBool('isFreelancing') ?? false;
    });
  }

  Future<void> _toggleMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFreelancing = !isFreelancing;
      prefs.setBool('isFreelancing', isFreelancing);
      _selectedIndex = 0; // Reset to the first screen after mode switch
      _pageController.jumpToPage(0); // Ensure the page changes
    });
  }

  List<Widget> _getFreelancerScreens() {
    return [
      const Freelanceboard(),
      const ProjectScreen(),
      const ResumeBuilder(),
      const LearningHub(),
      const PaymentSystem(),
    ];
  }

  List<Widget> _getClientScreens() {
    return [
      const Dashboard(),
      const ProjectScreen(),
      const ProfileScreen(),
      const PaymentSystem(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens =
        isFreelancing ? _getFreelancerScreens() : _getClientScreens();

    final List<NavigationDestination> destinations = isFreelancing
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_max_rounded),
              selectedIcon: Icon(Icons.home_max_rounded, color: Colors.blue),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon:
                  Icon(Icons.work_outline_rounded, color: Colors.blue),
              label: "Projects",
            ),
            NavigationDestination(
              icon: Icon(Icons.description_rounded),
              selectedIcon: Icon(Icons.description_rounded, color: Colors.blue),
              label: "Resume",
            ),
            NavigationDestination(
              icon: Icon(Icons.book_online_rounded),
              selectedIcon: Icon(Icons.book_online_rounded, color: Colors.blue),
              label: "E-learning",
            ),
            NavigationDestination(
              icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(Icons.payment_outlined, color: Colors.blue),
              label: "Payments",
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_max_rounded),
              selectedIcon: Icon(Icons.home_max_rounded, color: Colors.blue),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon:
                  Icon(Icons.work_outline_rounded, color: Colors.blue),
              label: "Projects",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.blue),
              label: "Profile",
            ),
            NavigationDestination(
              icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(Icons.payment_outlined, color: Colors.blue),
              label: "Payments",
            ),
          ];

    return Scaffold(
      // appBar: AppBar(
      //   title: Switch(
      //     value: isFreelancing,
      //     onChanged: (bool value) {
      //       _toggleMode();
      //     },
      //     activeColor: Colors.blue, // Color when in freelancing mode
      //     inactiveThumbColor: Colors.grey, // Color when in client mode
      //     inactiveTrackColor:
      //         Colors.grey.withOpacity(0.5), // Track color when inactive
      //   ),
      // ),
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.blue.shade100,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          iconTheme: MaterialStateProperty.all(
            const IconThemeData(size: 24),
          ),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
              _pageController.jumpToPage(index);
            });
          },
          destinations: destinations,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
