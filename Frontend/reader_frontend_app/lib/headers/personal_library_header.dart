import 'package:flutter/material.dart';

class PersonalLibraryHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  const PersonalLibraryHeader({super.key, 
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1E0F29),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Garante que a altura é mínima e não causa overflow
        children: [
          AppBar(
            backgroundColor: Color(0xFF1E0F29),
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min, // Mantém os itens centrados
              children: [
                Text(
                  "read.er",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  "Library",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.person_outline, color: Colors.white),
              onPressed: onProfileTap,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: onSettingsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 1); // Inclui o divisor na altura
}
