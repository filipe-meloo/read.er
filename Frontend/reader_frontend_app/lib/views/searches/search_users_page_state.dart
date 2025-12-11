import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import '/services/friendship_service.dart';
import 'package:reader_frontend_app/headers/search_header.dart';

class SearchUsersPage extends StatefulWidget {
  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
  FriendshipService userFriendshipService = FriendshipService();

  SearchUsersPage({super.key});
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  String? errorMessage;

  Future<void> _searchUsers(String query) async {
    try {
      final headers = await AuthProvider.getHeaders(); 
      final results = await FriendshipService.searchUsers(query, headers);

      setState(() {
        searchResults = results;
        errorMessage = results.isEmpty ? "Nenhum usuário encontrado." : null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao buscar usuários: $e';
      });
    }
  }

  Future<void> _sendFriendRequest(int id, String username) async {
    try {
      await FriendshipService.sendFriendRequest(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido enviado para @$username')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pedido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C1B3A),
      body: Column(
        children: [
          SearchHeader(
            searchController: _searchController,
            onSearch: _searchUsers,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(user['name'], style: TextStyle(color: Colors.white)),
                          subtitle: Text("@${user['username']}", style: TextStyle(color: Colors.grey)),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _sendFriendRequest(user['id'], user['username']);
                            },
                            child: Text('Adicionar'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
