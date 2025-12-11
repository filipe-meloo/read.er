import 'package:flutter/material.dart';

class AutorBottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AutorBottomNavigationBarWidget({super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      backgroundColor: Color(0xFF1E0F29),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
      items: [

        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), // Ícone da homepage
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: 'Search',
        ),
      ],
    );
  }
}