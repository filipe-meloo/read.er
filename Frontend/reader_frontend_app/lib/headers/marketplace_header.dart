import 'package:flutter/material.dart';

class MarketplaceHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearch;
  final TabController tabController; // Controlador de abas

  const MarketplaceHeader({super.key, 
    required this.onSearch,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: Color(0xFF1E0F29),
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
                color: Colors.white, // Barra divisória branca
              ),
              SizedBox(width: 8),
              Text(
                "Marketplace",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: onSearch,
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ),

        TabBar(
          controller: tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange, 
          tabs: [
            Tab(text: "Market"),
            Tab(text: "Offers"),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 48); // Altura para incluir o TabBar
}
