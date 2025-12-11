import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/post_service.dart';
import '../../services/community_service.dart';

class CreateCommunityPostWidget extends StatefulWidget {
  final Function onPostCreated;

  const CreateCommunityPostWidget({
    required this.onPostCreated,
    super.key,
  });

  @override
  _CreateCommunityPostWidgetState createState() =>
      _CreateCommunityPostWidgetState();
}

class _CreateCommunityPostWidgetState extends State<CreateCommunityPostWidget> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _bookTitleController = TextEditingController();
  String? selectedCommunity;
  String? selectedTopic;
  String? selectedPublicationType = "Critica"; // Tipo padrão
  List<CommunityModel> userCommunities = [];
  List<dynamic> communityTopics = [];
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadUserCommunities();
  }

  Future<void> _loadUserCommunities() async {
    try {
      final communities = await CommunityService.fetchUserCommunities();
      setState(() {
        userCommunities = communities;
        // Se há comunidades disponíveis, selecionar a primeira automaticamente
        if (userCommunities.isNotEmpty) {
          selectedCommunity = userCommunities.first.id.toString();
          _loadCommunityTopics(selectedCommunity!);
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar comunidades: $error")),
      );
    }
  }

  Future<void> _loadCommunityTopics(String communityId) async {
    try {
      final topics = await CommunityService().fetchCommunityTopics(
          int.parse(communityId));
      setState(() {
        communityTopics = topics;
        selectedTopic = null; // Limpar o tópico ao mudar de comunidade
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar tópicos: $error")),
      );
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("O conteúdo do post não pode estar vazio.")),
      );
      return;
    }

    if (selectedCommunity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione uma comunidade.")),
      );
      return;
    }

    if (selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um tópico.")),
      );
      return;
    }

    setState(() {
      isPosting = true;
    });

    try {
      await PostService.createCommunityPost(
        content: _contentController.text,
        tipoPublicacao: selectedPublicationType!,
        communityId: int.parse(selectedCommunity!),
        topicId: int.parse(selectedTopic!),
        tituloLivro: _bookTitleController.text.isNotEmpty
            ? _bookTitleController.text
            : null,
      );
      widget.onPostCreated();
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar o post: $error")),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery
          .of(context)
          .viewInsets,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF2C1B3A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown para selecionar a comunidade
              DropdownButton<String>(
                value: selectedCommunity,
                onChanged: (value) {
                  setState(() {
                    selectedCommunity = value;
                    communityTopics = [];
                  });
                  if (value != null) {
                    _loadCommunityTopics(value);
                  }
                },
                items: userCommunities.map((community) {
                  return DropdownMenuItem<String>(
                    value: community.id.toString(),
                    child: Text(
                      community.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                hint: const Text(
                  "Selecione uma comunidade",
                  style: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF3E2F51),
              ),
              const SizedBox(height: 10),

              // Dropdown para tópicos
              DropdownButton<String>(
                value: selectedTopic,
                onChanged: (value) {
                  setState(() {
                    selectedTopic = value;
                  });
                },
                items: communityTopics.map((topic) {
                  return DropdownMenuItem<String>(
                    value: topic['id'].toString(),
                    child: Text(
                      topic['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                hint: const Text(
                  "Selecione um tópico",
                  style: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF3E2F51),
              ),
              const SizedBox(height: 10),

              // Dropdown para tipo de publicação
              DropdownButton<String>(
                value: selectedPublicationType,
                onChanged: (value) {
                  setState(() {
                    selectedPublicationType = value;
                  });
                },
                items: ["Critica", "Dúvida", "Recomendação"].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                hint: const Text(
                  "Selecione o tipo de publicação",
                  style: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF3E2F51),
              ),
              const SizedBox(height: 10),

              // Campo para conteúdo
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: "Escreva seu post...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF3E2F51),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLength: 1000,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),

              // Campo para título do livro
              TextField(
                controller: _bookTitleController,
                decoration: InputDecoration(
                  hintText: "Título do livro (opcional)",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF3E2F51),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Botão de postar
              Center(
                child: ElevatedButton(
                  onPressed: isPosting ? null : _submitPost,
                  child: Text(isPosting ? "Postando..." : "Postar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
