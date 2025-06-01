import 'package:flutter/material.dart';
import 'package:freelance_system/screens/dashboard.dart';
import 'package:freelance_system/screens/profile.dart';
import 'package:freelance_system/screens/project.dart';
import 'package:freelance_system/screens/resume.dart';
import 'package:freelance_system/screens/elearning.dart';

class NavigationMenu extends StatefulWidget {
  final int initialIndex;
  const NavigationMenu({super.key, required this.initialIndex});

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
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    screens = [
      const Dashboard(),
      const ProjectScreen(),
      const ResumeScreen(),
      const LearningHub(),
      const ProfileScreen(),
    ];
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(238, 0, 128, 255),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                _pageController.jumpToPage(index);
              });
            },
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            showUnselectedLabels: false,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.white,
            items: List.generate(5, (index) {
              return BottomNavigationBarItem(
                  icon: _buildNavItem(index), label: '');
            }),
          ),
        ),
      ),
    );
  }

  final List<IconData> _icons = [
    Icons.home_max_rounded,
    Icons.work_outline_rounded,
    Icons.description_rounded,
    Icons.book,
    Icons.person,
  ];

  final List<String> _labels = [
    "Home",
    "Projects",
    "Resume",
    "E-learning",
    "Profile",
  ];

  Widget _buildNavItem(int index) {
    final bool isSelected = index == _selectedIndex;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 4), // Padding remains same
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: SizedBox(
        width: 70, // Fixed width for equal sizing of nav items
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[index],
              color: isSelected ? Colors.black : Colors.white,
              size: isSelected ? 24 : 24, // Icon size remains the same
            ),
            Text(
              _labels[index],
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: isSelected ? 12 : 12, // Text size remains the same
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
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
