import 'package:flutter/material.dart';

class FriendsListModal extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final Function(int) onRemoveFriend;

  const FriendsListModal({super.key, required this.friends, required this.onRemoveFriend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black, // Fundo escuro
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Meus Amigos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: friends.isEmpty
                ? Center(
              child: Text(
                "Você não tem amigos no momento.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final friendName = friend['FriendName'] ?? 'Nome desconhecido';
                final friendId = friend['FriendId'] ?? 0;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple,
                        child: Text(
                          friendName.isNotEmpty ? friendName[0].toUpperCase() : "?",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Nome e descrição
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (friendId != 0) {
                              Navigator.pushNamed(
                                context,
                                '/other-user-profile',
                                arguments: friendId,
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friendName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "@${friendName.toLowerCase().replaceAll(" ", "_")}",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botão de ação
                      TextButton(
                        onPressed: friendId != 0
                            ? () => _showConfirmationModal(context, friendName, friendId)
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Amigo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationModal(BuildContext context, String friendName, int friendId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            "Confirmar",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Tem certeza de que deseja deixar de ser amigo de $friendName?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o modal
              },
              child: Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o modal
                onRemoveFriend(friendId); // Remove o amigo
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Sim"),
            ),
          ],
        );
      },
    );
  }
  
  
}

