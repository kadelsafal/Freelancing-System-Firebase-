import 'package:flutter/material.dart';
import 'package:freelance_system/screens/dashboard.dart';
import 'package:freelance_system/screens/project.dart';
import 'package:freelance_system/screens/resume.dart';
import 'package:freelance_system/screens/elearning.dart';
import 'package:freelance_system/screens/payment.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> screens = [
    const Dashboard(),
    const ProjectScreen(),
    const ResumeScreen(),
    const LearningHub(),
    const PaymentSystem(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
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
          backgroundColor: Colors.white, // Changed from transparent to white
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (_selectedIndex != index) {
              setState(() {
                _selectedIndex = index;
                _pageController.jumpToPage(index);
              });
            }
          },
          destinations: const [
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
            )
          ],
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
