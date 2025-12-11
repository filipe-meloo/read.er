import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class CommunityManagementView extends StatefulWidget {
  @override
  _CommunityManagementViewState createState() =>
      _CommunityManagementViewState();
}

class _CommunityManagementViewState extends State<CommunityManagementView> {
  late Future<List<dynamic>> _futureCommunities;

  @override
  void initState() {
    super.initState();
    _futureCommunities = AdminService.fetchCommunities();
  }

  void _refreshCommunities() {
    setState(() {
      _futureCommunities = AdminService.fetchCommunities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestão de Comunidades")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureCommunities,
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

          final communities = snapshot.data ?? [];
          if (communities.isEmpty) {
            return Center(
              child: Text("Nenhuma comunidade encontrada."),
            );
          }

          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              final isBlocked = community['isBlocked'] ?? false;

              return ListTile(
                title: Text(community['name'] ?? 'Nome não disponível'),
                trailing: IconButton(
                  icon: Icon(
                    isBlocked ? Icons.lock : Icons.lock_open,
                    color: isBlocked ? Colors.red : Colors.green,
                  ),
                  onPressed: () async {
                    final action = isBlocked ? 'desbloquear' : 'bloquear';
                    final function = isBlocked
                        ? AdminService.unblockCommunity
                        : AdminService.blockCommunity;

                    try {
                      await function(community['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Comunidade $action com sucesso!"),
                        ),
                      );
                      _refreshCommunities(); // Atualiza a lista de comunidades
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erro ao $action a comunidade: $error"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
