import 'package:flutter/material.dart';


class UserProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  const UserProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2C1B3A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context); // Voltar para a última página acessada
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'read.er ',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '| Profile',
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
