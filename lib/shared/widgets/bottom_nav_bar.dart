import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'PROJECTS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'SEARCH',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_border),
          label: 'STARRED',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'SETTINGS',
        ),
      ],
    );
  }
}
