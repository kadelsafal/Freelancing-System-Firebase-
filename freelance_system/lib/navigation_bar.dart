import 'package:flutter/material.dart';
import 'package:freelance_system/screens/dashboard.dart';
import 'package:freelance_system/screens/project.dart';
import 'package:freelance_system/screens/resume.dart';
import 'package:freelance_system/screens/elearning.dart';
import 'package:freelance_system/screens/payment.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  late PageController _pageController;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    // Safely initialize screens with fallback widgets in case any screen fails
    screens = [
      const Dashboard(),
      _safeScreen(const ProjectScreen()),
      _safeScreen(const ResumeScreen()),
      _safeScreen(const LearningHub()),
      _safeScreen(const PaymentSystem()),
    ];
  }

  Widget _safeScreen(Widget screen) {
    try {
      return screen;
    } catch (e) {
      return Center(child: Text("Failed to load screen: $e"));
    }
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
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(size: 24),
          ),
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
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
