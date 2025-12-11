import 'package:flutter/material.dart';

class HomePageHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTapped;

  const HomePageHeader({super.key, required this.onMenuTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C1B3A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Garante que os itens ficam na parte inferior
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: const Color(0xFF2C1B3A),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.person_2_outlined,
                color: Colors.white,
                size: 24, // Tamanho do ícone
              ),
              onPressed: onMenuTapped,
            ),
            title: const Text(
              "read.er | Home",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, '/logout');
                },
              ),
            ],
          ),
          const Divider(
            color: Colors.white,
            thickness: 1,
            height: 1, // Evita espaço extra
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2); // Ajusta o tamanho total para incluir a divisão
}
