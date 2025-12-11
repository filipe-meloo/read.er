import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';

import '../../services/config.dart';
import '../../services/friendship_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  List<Map<String, dynamic>> friendRequests = [];
  bool isLoading = true;
  String? errorMessage;


  Future<void> _fetchFriendRequests() async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/GetFriendRequests');
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        try {
          // Tenta decodificar a resposta como JSON
          final List<dynamic> requests = json.decode(response.body);
          setState(() {
            friendRequests = requests.map((request) {
              return {
                'id': request['requesterId'],
                'name': request['requesterName'],
              };
            }).toList();
            errorMessage = null; // Remove qualquer mensagem de erro
          });
        } catch (e) {
          // Se falhar ao decodificar, considera que não há solicitações
          setState(() {
            friendRequests = [];
            errorMessage = "Nenhuma solicitação de amizade no momento.";
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          friendRequests = [];
          errorMessage = "Nenhuma solicitação de amizade no momento.";
        });
      } else {
        throw Exception("Erro ao buscar solicitações: ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() {
        friendRequests = [];
        errorMessage = "Erro ao buscar solicitações: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFriendRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Solicitações de amizade",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C1A3D), // Cor dos headers restantes
        iconTheme: const IconThemeData(color: Colors.white), // Cor da seta para trás
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Voltar para a página anterior
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendRequests.isEmpty
          ? Center(
        child: Text(
          errorMessage ?? "Nenhuma solicitação de amizade no momento.",
          style: const TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: friendRequests.length,
        itemBuilder: (context, index) {
          final request = friendRequests[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(request['name']),
            subtitle: Text("ID: ${request['id']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    try {
                      await FriendshipService.acceptFriendRequest(request['id']); // Aceita solicitação
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Solicitação de amizade de ${request['name']} aceita!',
                          ),
                        ),
                      );
                      setState(() {
                        friendRequests.removeAt(index);
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao aceitar solicitação: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Aceitar"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    try {
                      await FriendshipService.declineFriendRequest(request['id']); // Recusa solicitação
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Solicitação de amizade de ${request['name']} recusada.',
                          ),
                        ),
                      );
                      setState(() {
                        friendRequests.removeAt(index);
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao recusar solicitação: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Recusar"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
