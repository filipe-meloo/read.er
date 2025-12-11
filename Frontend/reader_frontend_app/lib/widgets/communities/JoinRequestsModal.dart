import 'package:flutter/material.dart';
import '../../services/community_service.dart';

class JoinRequestsModal extends StatefulWidget {
  final int communityId;

  const JoinRequestsModal({
    super.key,
    required this.communityId,
  });

  @override
  State<JoinRequestsModal> createState() => _JoinRequestsModalState();
}

class _JoinRequestsModalState extends State<JoinRequestsModal> {
  final CommunityService _communityService = CommunityService();

  List<dynamic> pendingRequests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final requests = await _communityService.fetchPendingRequests(widget.communityId);
      setState(() {
        pendingRequests = requests;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar pedidos pendentes: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(int userId) async {
    try {
      // Chamar o serviço para aprovar o pedido
      await _communityService.approveRequest(widget.communityId, userId);

      // Atualizar a lista de pedidos pendentes
      setState(() {
        pendingRequests.removeWhere((request) => request['userId'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido aprovado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao aprovar o pedido: $e")),
      );
    }
  }


  Future<void> _rejectRequest(int userId) async {
    try {
      await _communityService.rejectRequest(widget.communityId, userId);
      setState(() {
        pendingRequests.removeWhere((request) => request['userId'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido rejeitado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao rejeitar o pedido: $e")),
      );
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
            'Pedidos de Adesão',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (pendingRequests.isEmpty)
              const Center(
                child: Text(
                  'Nenhum pedido pendente.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = pendingRequests[index];
                  return ListTile(
                    title: Text(
                      request['username'] ?? 'Usuário',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveRequest(request['userId']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectRequest(request['userId']),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
