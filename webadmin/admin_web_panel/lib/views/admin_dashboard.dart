import 'package:admin_web_panel/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../widgets/chart_widget.dart';
import '../services/admin_service.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _checkLoginStatus(context);

    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "read.er",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inknut Antiqua',
                color: Colors.black,
              ),
            ),
            if (!isSmallScreen)
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildNavbarItem(context, "Gestão de Utilizadores",
                          "/user-management"),
                      _buildNavbarItem(context, "Gestão de Comunidades",
                          "/community-management"),
                      _buildNavbarItem(
                          context, "Gestão de Reports", "/reports-management"),
                      _buildNavbarItem(context, "Gestão de Transações",
                          "/transaction-management"),
                      _buildNavbarItem(context, "Aprovação de Livros",
                          "/book-approval-management"),
                      _buildNavbarItem(
                          context, "Gestão de Posts", "/post-management"),
                      _buildNavbarItem(context, "Logout", "/logout"),
                    ],
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  _showPopupMenu(context);
                },
              ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: AdminService.fetchMetrics([
            "totalUsers",
            "totalCachedBooks",
            "totalDailyPosts",
            "totalInteractions",
            "reportedPosts",
            "mostActiveUsers",
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Erro: ${snapshot.error}",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            final metrics = snapshot.data ?? {};

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard("Utilizadores", metrics["totalUsers"] ?? 0,
                          Colors.green),
                      _buildInfoCard("Livros Em Cache",
                          metrics["totalCachedBooks"] ?? 0, Colors.blue),
                      _buildInfoCard("Posts Reportados",
                          metrics["reportedPosts"] ?? 0, Colors.red),
                    ],
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: ChartWidget(
                        data: [
                          (metrics["totalDailyPosts"] ?? 0).toDouble(),
                          (metrics["totalInteractions"] ?? 0).toDouble(),
                        ],
                        labels: ["Posts Diários", "Interações"],
                        title: "Métricas de Atividade",
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: AdminService.fetchUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erro ao carregar utilizadores: ${snapshot.error}",
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        );
                      }

                      final users = snapshot.data ?? [];

                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            "Nenhum utilizador encontrado.",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Utilizadores Mais Recentes",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Divider(),
                              for (var user in users)
                                ListTile(
                                  title: Text(
                                    user["nome"],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(user["email"]),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _checkLoginStatus(BuildContext context) async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  Widget _buildNavbarItem(BuildContext context, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, int value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                value.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              title: Text("Gestão de Utilizadores"),
              onTap: () => Navigator.pushNamed(context, "/user-management"),
            ),
            ListTile(
              title: Text("Gestão de Comunidades"),
              onTap: () =>
                  Navigator.pushNamed(context, "/community-management"),
            ),
            ListTile(
              title: Text("Gestão de Reports"),
              onTap: () => Navigator.pushNamed(context, "/reports-management"),
            ),
            ListTile(
              title: Text("Gestão de Transações"),
              onTap: () =>
                  Navigator.pushNamed(context, "/transaction-management"),
            ),
            ListTile(
              title: Text("Aprovação de Livros"),
              onTap: () =>
                  Navigator.pushNamed(context, "/book-approval-management"),
            ),
            ListTile(
              title: Text("Gestão de Posts"),
              onTap: () => Navigator.pushNamed(context, "/post-management"),
            ),
            ListTile(
              title: Text("Logout"),
              onTap: () async {
                await AuthService.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context, "/", (route) => false);
              },
            ),
          ],
        );
      },
    );
  }
}
