import 'package:flutter/material.dart';
import '../../widgets/userprofile/friends_list_modal.dart';
import '../../widgets/userprofile/profile_picture_uploader.dart';
import '../../widgets/posts/comments_modal.dart';
import '../../widgets/posts/post_list_widget.dart';
import '../../models/user.dart';
import '../../services/friendship_service.dart';
import '/services/post_service.dart';
import '/services/user_profile_service.dart';
import '/models/post_model.dart';
import '/headers/user_profile_header.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int booksReadedCount = 0;
  int friendsCount = 0;
  List<PostModel> userPosts = [];
  bool isLoading = true;
  String? errorMessage;
  User? user; // Variável para armazenar o objeto do usuário.

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }


  void _updateProfilePicture(String url) {
    setState(() {
      if (user != null) {
        user!.profilePictureUrl = url;
      }
    });
    print("URL da imagem de perfil atualizada: $url"); // Log de depuração.
  }

  Future<void> _loadUserProfileData() async {
    try {
      final fetchedUser = await UserProfileService.fetchUserProfile();
      setState(() {
        user = fetchedUser; // Atualiza o estado com o usuário carregado.
        print(
            "Imagem carregada do backend: ${user?.profilePictureUrl}"); // Verifica a URL recebida
      });
      await Future.wait([
        _fetchUserBooksReadedCount(),
        _fetchFriendsCount(),
        _loadUserPosts(),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar dados do perfil: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Busca o número de livros lidos pelo usuário.
  Future<void> _fetchUserBooksReadedCount() async {
    try {
      final count = await UserProfileService.fetchBooksReadedCount();
      setState(() {
        booksReadedCount = count;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao buscar livros lidos: $e";
      });
    }
  }

  /// Busca o número de amigos do usuário.
  Future<void> _fetchFriendsCount() async {
    try {
      final count = await UserProfileService.fetchFriendsCount();
      setState(() {
        friendsCount = count;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao buscar amigos: $e";
      });
    }
  }

  /// Carrega os posts do usuário.
  Future<void> _loadUserPosts() async {
    try {
      final fetchedPosts = await PostService.fetchUserPosts();
      setState(() {
        userPosts = fetchedPosts;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar posts: $e";
      });
    }
  }

  /// Função para reagir a um post.
  void _reactToPost(int postId, String reactionType) async {
    try {
      await PostService.reactToPost(postId, reactionType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Você reagiu com $reactionType ao post $postId")),
      );
      _loadUserPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao reagir ao post: $e")),
      );
    }
  }

  /// Abre o modal para comentar em um post.
  void _commentOnPost(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CommentsModal(
          postId: postId,
          onCommentAdded: () {
            setState(() {
              final post = userPosts.firstWhere((p) => p.id == postId);
              post.numberOfComments += 1;
            });
          },
        );
      },
    );
  }

  /// Compartilha um post.
  void _sharePost(int postId) async {
    try {
      await PostService.sharePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post partilhado com sucesso!')),
      );
      _loadUserPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao partilhar o post: $e')),
      );
    }
  }

  /// Exibe a lista de amigos do usuário.
  void _viewFriends() async {
    final friends = await FriendshipService.fetchFriends();
    if (friends.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return FriendsListModal(
            friends: friends,
            onRemoveFriend: _removeFriend,
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você não tem amigos.')),
      );
    }
  }

  /// Remove um amigo da lista de amigos.
  void _removeFriend(int friendId) async {
    try {
      await FriendshipService.removeFriend(friendId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amizade removida com sucesso.')),
      );
      _fetchFriendsCount();
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao remover amigo: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A),
      appBar: const UserProfileHeader(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(
                  child: Text(
                    'Erro ao carregar o perfil.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (BuildContext context) {
                                  return Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2C1B3A),
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    child: ProfilePictureUploader(
                                      onUploadComplete: _updateProfilePicture,
                                    ),
                                  );
                                },
                              );
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.purple,
                                  backgroundImage: user?.profilePictureUrl !=
                                          null
                                      ? NetworkImage(user!.profilePictureUrl!)
                                      : null,
                                  child: user?.profilePictureUrl == null
                                      ? const Icon(Icons.person,
                                          color: Colors.white, size: 30)
                                      : null,
                                ),
                                const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.edit,
                                      color: Colors.purple, size: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? "Usuário",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildStatistic(Icons.book,
                                        "$booksReadedCount", "Books", () {}),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: _viewFriends,
                                      child: _buildStatistic(Icons.people,
                                          "$friendsCount", "Friends", _viewFriends),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatistic(
                                        Icons.groups, "20", "Communities", () {}),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  user?.bio ?? "Nenhuma biografia disponível.",
                                  style: const TextStyle(
                                    color: Colors
                                        .white, // Tornar o texto branco para contraste
                                    fontSize: 16, // Aumentar o tamanho da fonte
                                    fontStyle:
                                        FontStyle.italic, // Adicionar itálico
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white, thickness: 1),
                      const SizedBox(height: 16),
                      Text(
                        "My Posts",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: userPosts.isEmpty
                            ? const Center(
                                child: Text(
                                  "Sem publicações no momento.",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : PostListWidget(
                                posts: userPosts,
                                onReact: _reactToPost,
                                onComment: _commentOnPost,
                                onShare: _sharePost,
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

Widget _buildStatistic(IconData icon, String value, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  );
}

}
