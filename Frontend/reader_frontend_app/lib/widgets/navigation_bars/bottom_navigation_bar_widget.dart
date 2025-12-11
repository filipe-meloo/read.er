import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool isReader;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isReader,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (isReader || index == 2) {
          onTabSelected(index);
        }
      },
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
          icon: Icon(Icons.storefront_outlined),
          label: 'Store',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: 'Search',
        ),
      ],
    );
  }
}
