import 'package:flutter/material.dart';

class UserCommunitiesModal extends StatelessWidget {
  final List<Map<String, dynamic>> communities;
  final Function(int) onLeaveCommunity;

  const UserCommunitiesModal({
    super.key,
    required this.communities,
    required this.onLeaveCommunity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Minhas Comunidades",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: communities.isEmpty
                ? Center(
              child: Text(
                "Você não está em nenhuma comunidade no momento.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                final communityName = community['name'] ?? 'Nome desconhecido';
                final communityId = community['id'] ?? 0;
                final communityDescription = community['description'] ?? '';
                final communityImage = community['image'] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple,
                        backgroundImage: communityImage.isNotEmpty
                            ? NetworkImage(communityImage)
                            : null,
                        child: communityImage.isEmpty
                            ? Text(
                          communityName.isNotEmpty
                              ? communityName[0].toUpperCase()
                              : "?",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                            : null,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (communityId != 0) {
                              Navigator.pushNamed(
                                context,
                                '/community/$communityId',
                                arguments: {
                                  'name': communityName,
                                  'description': communityDescription,
                                  'image': communityImage,
                                },
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                communityName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                communityDescription,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: communityId != 0
                            ? () => _showConfirmationModal(
                          context,
                          communityName,
                          communityId,
                        )
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Membro",
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

  void _showConfirmationModal(BuildContext context, String communityName, int communityId) {
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
            "Tem certeza de que deseja sair da comunidade $communityName?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLeaveCommunity(communityId);
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
