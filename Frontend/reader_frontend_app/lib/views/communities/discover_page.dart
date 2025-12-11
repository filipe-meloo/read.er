import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/community_service.dart';
import '../../services/config.dart';
import 'community_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<dynamic> recommendedCommunities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedCommunities();
  }

  Future<void> _fetchRecommendedCommunities() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/Community/RecommendedCommunities'),
      );
      if (response.statusCode == 200) {
        setState(() {
          recommendedCommunities = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load communities");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching recommended communities: $e");
    }
  }

  Future<void> _createCommunity(String name, String description) async {
    try {
      // Chama o método do CommunityService para criar a comunidade
      await CommunityService().createCommunity(name, description);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comunidade criada com sucesso!")),
      );

      // Atualiza a lista de comunidades recomendadas
      await _fetchRecommendedCommunities();
    } catch (e) {
      // Exibe a mensagem de erro ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar comunidade: $e")),
      );
    }
  }

  void _showCreateCommunityModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF2C1B3A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Criar Comunidade',
                  style: TextStyle(color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nome da comunidade',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF241731),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Descrição da comunidade',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF241731),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final description = descriptionController.text.trim();

                    if (name.isEmpty || description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                            "Preencha todos os campos!")),
                      );
                      return;
                    }

                    Navigator.pop(context); // Fecha o modal
                    _createCommunity(name,
                        description); // Chama o método para criar a comunidade
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('Criar Comunidade'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recommended for you",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendedCommunities.length,
              itemBuilder: (context, index) {
                final community = recommendedCommunities[index];
                return _buildRecommendedCommunityCard(
                  context,
                  name: community['name'],
                  members: "${community['memberCount']} Members",
                  memberImages: community['memberImages'] ?? [],
                  profilePicture: community['profilePicture'],
                  // Passa a imagem de perfil
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CommunityPage(
                              communityName: community['name'],
                              communityDescription: community['description'],
                              communityImage: community['profilePicture'] ?? '',
                              communityId: community['id'],
                            ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCommunityModal,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecommendedCommunityCard(BuildContext context, {
    required String name,
    required String members,
    required List<dynamic> memberImages,
    required VoidCallback onTap,
    String? profilePicture, // Adiciona o parâmetro para a imagem de perfil da comunidade
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Verifica se há uma `profilePicture` e exibe-a
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: profilePicture != null
                  ? DecorationImage(
                image: NetworkImage(profilePicture),
                fit: BoxFit.cover,
              )
                  : null,
              color: profilePicture == null ? Colors.grey : null,
            ),
            child: profilePicture == null
                ? const Icon(Icons.group, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  members,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: memberImages.map((imageUrl) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: CircleAvatar(
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        radius: 12,
                        backgroundColor: Colors.grey,
                        child: imageUrl == null
                            ? const Icon(
                            Icons.person, size: 12, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
