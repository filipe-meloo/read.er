import 'package:flutter/material.dart';

class CommunityHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onSearchTap;
  final VoidCallback onMembersTap;
  final VoidCallback onMenuTapped; // Nova callback
  final int currentIndex;
  final Function(int) onTabChanged;

  const CommunityHeader({
    super.key,
    required this.title,
    required this.onSearchTap,
    required this.onMembersTap,
    required this.onMenuTapped, // Receber a callback
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2C1B3A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuTapped, // Chama a lógica de abertura da navbar
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: currentIndex == 0 ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Communities",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: currentIndex == 1 ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Discover",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: onSearchTap,
        ),
        IconButton(
          icon: const Icon(Icons.group, color: Colors.white),
          onPressed: onMembersTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100.0);
}
