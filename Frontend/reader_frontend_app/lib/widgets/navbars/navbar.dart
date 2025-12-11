import 'package:flutter/material.dart';

class NavbarContent extends StatelessWidget {
  final int friendRequestsCount;
  final bool hasOwnedCommunities;
  final bool isReader;

  const NavbarContent({
    super.key,
    required this.friendRequestsCount,
    required this.hasOwnedCommunities,
    required this.isReader,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF2C1B3A),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão Home
          ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text('User Profile', style: TextStyle(color: Colors.white54)),
            onTap: () {
              Navigator.pushNamed(context, '/user-profile');
            },
          ),
          // Botão Procurar Usuários (apenas para leitores)
          if (isReader)
            ListTile(
              leading: Icon(Icons.search, color: Colors.white),
              title: Text('Procurar usuários', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pushNamed(context, '/search-users');
              },
            ),
          // Botão Solicitações de Amizade
          ListTile(
            leading: Stack(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                if (friendRequestsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$friendRequestsCount',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text('Friend Requests', style: TextStyle(color: Colors.white54)),
            onTap: () {
              Navigator.pushNamed(context, '/friend-requests');
            },
          ),
          // Botão Notificações
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.white),
            title: Text('Notifications', style: TextStyle(color: Colors.white54)),
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          // Botão Communities Owned (Apenas para admins)
          if (hasOwnedCommunities)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.white),
              title: Text('Communities Owned', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pushNamed(context, '/my-communities');
              },
            ),
          // Botão Configurações
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pushNamed(context, '/profile/update');

            },
          ),
        ],
      ),
    );
  }
}
