import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/community_post_model.dart';
import 'package:http/http.dart' as http;

import '../../services/community_service.dart';
import '../../services/config.dart';
import '../../widgets/posts/comments_modal.dart';
import '../../widgets/posts/create_community_post_widget.dart';
import '../../widgets/posts/post_list_widget.dart';


class CommunityPage extends StatefulWidget {
  final int communityId;
  final String communityName;
  final String communityDescription;
  String communityImage;


  CommunityPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.communityDescription,
    required this.communityImage,

  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  List<CommunityPostModel> communityPosts = [];
  bool isLoading = true;
  String? errorMessage;
  bool isMember = false;  // Variável para armazenar o status de membro

  @override
  void initState() {
    super.initState();
    // Chama a função para verificar se o usuário é membro ao inicializar a página
    _fetchCommunityPosts();
    _checkIfUserIsMember();
  }

  Future<void> _fetchCommunityPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$BASE_URL/api/Community/GetCommunityPosts/${widget.communityId}'),
      );

      if (response.statusCode == 200) {
        final posts = (jsonDecode(response.body) as List)
            .map((post) => CommunityPostModel.fromJson(post))
            .toList();
        setState(() {
          communityPosts = posts;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erro ao carregar os posts da comunidade.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar os posts da comunidade: $e";
        isLoading = false;
      });
    }
  }


  // Função para o usuário sair da comunidade
  Future<void> _leaveCommunity() async {
    // Chamar a API para remover o usuário da comunidade (ou marcar o status de membro como 'não membro')
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/Community/LeaveCommunity/${widget.communityId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          isMember = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Você saiu da comunidade.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao sair da comunidade.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao sair da comunidade: $e")));
    }
  }

  // Função para cancelar o pedido de adesão
  Future<void> _cancelJoinRequest() async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/Community/CancelJoinRequest/${widget.communityId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          isMember = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pedido de adesão cancelado.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao cancelar o pedido.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao cancelar o pedido: $e")));
    }
  }

  // Função para enviar pedido de adesão
  Future<void> _joinCommunity() async {
    try {
      // Adicionando o role no corpo da requisição
      final response = await http.post(
        Uri.parse('$BASE_URL/api/Community/JoinRequest/${widget.communityId}/Membro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': 'membro',  // Define o papel como "membro"
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isMember = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pedido de adesão enviado com sucesso.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar pedido de adesão.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar pedido: $e")));
    }
  }




  void _showMemberActionModal() {
    if (isMember) {
      // Modal para Sair ou Cancelar
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: Text('Sair da Comunidade'),
                onTap: () {
                  _leaveCommunity();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.orange),
                title: Text('Cancelar Pedido'),
                onTap: () {
                  _cancelJoinRequest();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } else {
      // Modal para enviar Pedido de Adesão
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListTile(
            leading: Icon(Icons.person_add, color: Colors.green),
            title: Text('Enviar Pedido de Adesão'),
            onTap: () {
              _joinCommunity();
              Navigator.pop(context);
            },
          );
        },
      );
    }
  }



  void _checkIfUserIsMember() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Chama a função do serviço para verificar a adesão
      final isUserMember = await  CommunityService.checkIfUserIsMember(widget.communityId);

      setState(() {
        isMember = isUserMember;  // Define se o usuário é membro
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao verificar a adesão do usuário: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma imagem selecionada.")),
      );
      return;
    }

    final uri = Uri.parse(
        '$BASE_URL/api/Community/UploadCommunityPhoto/${widget.communityId}');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final imageUrl = jsonDecode(responseBody)['profilePictureUrl'];
        setState(() {
          widget.communityImage = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto atualizada com sucesso!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao atualizar a foto.")),
        );
      }
    } catch (e) {
      print("Erro ao fazer upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro no upload.")),
      );
    }
  }

  void _reactToPost(int postId, String reactionType) async {
    try {
      await http.post(
        Uri.parse('$BASE_URL/api/Post/React/$postId'),
        body: jsonEncode({'reactionType': reactionType}),
        headers: {'Content-Type': 'application/json'},
      );
      _fetchCommunityPosts();
    } catch (e) {
      print("Erro ao reagir ao post: $e");
    }
  }

  void _commentOnPost(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CommentsModal (
          postId: postId,
          onCommentAdded: () {
            setState(() {
              final post = communityPosts.firstWhere((p) => p.id == postId);
              post.numberOfComments += 1;
            });
          },
        );
      },
    );
  }

  void _sharePost(int postId) async {
    try {
      await http.post(
        Uri.parse('$BASE_URL/api/Post/Share/$postId'),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post partilhado com sucesso!")),
      );
    } catch (e) {
      print("Erro ao compartilhar o post: $e");
    }
  }

  void _openCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CreateCommunityPostWidget (
          onPostCreated: _fetchCommunityPosts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A),
      body: Column(
        children: [
          // Header com imagem e informações
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF241731), // Fallback para roxo escuro
                  image: widget.communityImage.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(widget.communityImage),
                    fit: BoxFit.cover,
                    onError: (_, __) {
                      setState(() {
                        widget.communityImage = ""; // Limpa a imagem inválida
                      });
                    },
                  )
                      : null,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      await _pickImage();
                      await _uploadImage();
                    },
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.communityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.communityDescription,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
                : isMember
                ? PostListWidget (
              posts: communityPosts,
              onReact: _reactToPost,
              onComment: _commentOnPost,
              onShare: _sharePost,
            )
                : Center(
              child: Text(
                "Adira já para ver os posts",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isMember
          ? FloatingActionButton(
        onPressed: () {
          _openCancelJoinModal(); // Função para cancelar a adesão
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.check_box_rounded), // Ícone para membros
      )
          : FloatingActionButton(
        onPressed: () {
          _openJoinRequestModal(); // Função para enviar pedido de adesão
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.person_add), // Ícone para não membros
      ),
    );
  }

  void _openJoinRequestModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check),
              title: Text('Enviar pedido de adesão'),
              onTap: () {
                // Aqui você chama a API para enviar o pedido de adesão
                _sendJoinRequest();
                Navigator.pop(context); // Fecha o modal
              },
            ),
          ],
        );
      },
    );
  }

  void _sendJoinRequest() async {
    try {
      await CommunityService().joinCommunity(widget.communityId, 'Member'); // Força o papel para "Member"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido de adesão enviado com sucesso!")),
      );
      setState(() {
        isMember = true; // Atualiza o estado para indicar que o usuário agora é membro
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar o pedido de adesão: $e")),
      );
    }
  }

  void _openCancelJoinModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cancelar adesão à comunidade'),
              onTap: () {
                // Aqui você chama a API para cancelar a adesão
                _cancelJoinRequest();
                Navigator.pop(context); // Fecha o modal
              },
            ),
          ],
        );
      },
    );
  }

}