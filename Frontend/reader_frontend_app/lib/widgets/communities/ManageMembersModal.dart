import 'package:flutter/material.dart';
import '../../services/community_service.dart';

class ManageMembersModal extends StatefulWidget {
  final int communityId;

  const ManageMembersModal({super.key, required this.communityId});

  @override
  _ManageMembersModalState createState() => _ManageMembersModalState();
}

class _ManageMembersModalState extends State<ManageMembersModal> {
  List<dynamic> members = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedMembers = await CommunityService().fetchCommunityMembers(widget.communityId);
      setState(() {
        members = fetchedMembers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar membros: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _removeMember(int memberNumber) async {
    try {
      await CommunityService().removeMember(widget.communityId, memberNumber);
      setState(() {
        members.removeWhere((member) => member['memberNumber'] == memberNumber);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membro removido com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover membro: $e')),
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
            'Gerir Membros',
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
          else if (members.isEmpty)
              const Center(
                child: Text(
                  'Nenhum membro encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member['profilePictureUrl'] != null
                            ? NetworkImage(member['profilePictureUrl'])
                            : null,
                        backgroundColor: Colors.grey,
                        child: member['profilePictureUrl'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        member['username'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'ID: ${member['memberNumber']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeMember(member['memberNumber']),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
