import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class UserManagement extends StatefulWidget {
  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  late Future<List<Map<String, dynamic>>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = AdminService.fetchUsers();
  }

  // Método para atualizar a lista de usuários
  void _refreshUsers() {
    setState(() {
      _futureUsers = AdminService.fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestão de Utilizadores"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureUsers,
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

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text("Nenhum utilizador encontrado."),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Use os switches para bloquear ou desbloquear utilizadores.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final nome = user["nome"] ?? "Desconhecido";
                    final id = user["id"] ?? "Sem ID";
                    final isActive = user["isActive"] ?? false;

                    return ListTile(
                      title: Text(nome),
                      subtitle: Text("ID: $id"),
                      trailing: Switch(
                        value: isActive,
                        onChanged: (value) async {
                          try {
                            await AdminService.toggleUserStatus(user["id"] ?? 0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value
                                    ? "$nome desbloqueado."
                                    : "$nome bloqueado."),
                              ),
                            );
                            _refreshUsers(); // Atualizar a lista após a mudança
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erro ao atualizar estado."),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
