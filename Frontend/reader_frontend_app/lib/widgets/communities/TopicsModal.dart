import 'package:flutter/material.dart';

import '../../services/community_service.dart';

class TopicsModal extends StatefulWidget {
  final int communityId;

  const TopicsModal({
    super.key,
    required this.communityId,
  });

  @override
  State<TopicsModal> createState() => _TopicsModalState();
}

class _TopicsModalState extends State<TopicsModal> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _topicController = TextEditingController();
  List<dynamic> topics = [];
  bool isLoading = true;
  bool isCreating = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedTopics = await _communityService.fetchCommunityTopics(widget.communityId);
      setState(() {
        topics = fetchedTopics;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar tópicos: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _toggleTopicStatus(int topicId, bool currentStatus) async {
    try {
      await _communityService.toggleTopicStatus(widget.communityId, topicId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tópico ${currentStatus ? "desbloqueado" : "bloqueado"} com sucesso!")),
      );

      // Atualizar a lista de tópicos após o toggle
      setState(() {
        final topic = topics.firstWhere((t) => t['id'] == topicId);
        topic['isBlocked'] = !currentStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao alternar o status do tópico: $e")),
      );
    }
  }

  Future<void> _createTopic() async {
    final topicName = _topicController.text.trim();

    if (topicName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O nome do tópico é obrigatório.")),
      );
      return;
    }

    setState(() {
      isCreating = true;
    });

    try {
      await _communityService.createTopic(widget.communityId, topicName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tópico criado com sucesso!")),
      );
      _topicController.clear();
      _fetchTopics(); // Atualiza a lista de tópicos após criação
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar tópico: $e")),
      );
    } finally {
      setState(() {
        isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2C1B3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tópicos da Comunidade',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : errorMessage != null
              ? Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
          )
              : Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return ListTile(
                  title: Text(
                    topic['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Switch(
                    value: topic['isBlocked'],
                    activeColor: Colors.white, // Bloqueado
                    inactiveThumbColor: Colors.blue, // Não bloqueado
                    onChanged: (value) {
                      _toggleTopicStatus(topic['id'], topic['isBlocked']);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              hintText: "Nome do novo tópico",
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
            onPressed: isCreating ? null : _createTopic,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: isCreating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Criar Novo Tópico'),
          ),
        ],
      ),
    );
  }
}
