import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../widgets/communities/JoinRequestsModal.dart';
import '../../widgets/communities/ManageMembersModal.dart';
import '../../widgets/communities/TopicsModal.dart';


class MyCommunitiesPage extends StatefulWidget {
  const MyCommunitiesPage({super.key});

  @override
  State<MyCommunitiesPage> createState() => _MyCommunitiesPageState();
}

class _MyCommunitiesPageState extends State<MyCommunitiesPage> {
  final CommunityService _communityService = CommunityService();

  List<dynamic> userOwnedCommunities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserOwnedCommunities();
  }

  Future<void> _fetchUserOwnedCommunities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final communities = await _communityService.fetchUserOwnedCommunities();
      setState(() {
        userOwnedCommunities = communities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar comunidades: $e";
        isLoading = false;
      });
    }
  }

  void _openModal(BuildContext context, Widget modal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => modal,
    ).then((_) {
      // Este código será executado após o modal ser fechado
      Navigator.pop(context); // Volta para a página anterior
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Comunidades"),
        backgroundColor: const Color(0xFF2C1B3A),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : ListView.builder(
        itemCount: userOwnedCommunities.length,
        itemBuilder: (context, index) {
          final community = userOwnedCommunities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: community['profilePictureUrl'] != null
                  ? NetworkImage(community['profilePictureUrl'])
                  : null,
              backgroundColor: Colors.grey,
              child: community['profilePictureUrl'] == null
                  ? const Icon(Icons.group, color: Colors.white)
                  : null,
            ),
            title: Text(
              community['name'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              community['description'] ?? 'Sem descrição',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'joinRequests') {
                  _openModal(context, JoinRequestsModal(communityId: community['id']));
                } else if (value == 'topics') {
                  _openModal(context, TopicsModal(communityId: community['id']));
                } else if (value == 'manageMembers') {
                  _openModal(context, ManageMembersModal(communityId: community['id']));
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'joinRequests',
                    child: Text('Pedidos de Adesão'),
                  ),
                  const PopupMenuItem(
                    value: 'topics',
                    child: Text('Tópicos'),
                  ),
                  const PopupMenuItem(
                    value: 'manageMembers',
                    child: Text('Gerir Membros'),
                  ),
                ];
              },
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFF2C1B3A),
    );
  }
}
