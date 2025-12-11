import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../widgets/posts/create_community_post_widget.dart';
import '../../widgets/posts/post_list_widget.dart';
import '/models/community_post_model.dart';
import '/services/community_service.dart';

class CommunitiesMainPage extends StatefulWidget {
  const CommunitiesMainPage({super.key});

  @override
  _CommunitiesMainPageState createState() => _CommunitiesMainPageState();
}

class _CommunitiesMainPageState extends State<CommunitiesMainPage> {
  List<CommunityPostModel> allCommunityPosts = [];
  List<CommunityModel> userCommunities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCommunities();
    _loadUserCommunityPosts();
  }

  Future<void> _loadUserCommunities() async {
    try {
      final communities = await CommunityService.fetchUserCommunities();
      setState(() {
        userCommunities = communities;
      });
      print("Comunidades carregadas: $userCommunities");
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar comunidades: $error")),
      );
    }
  }

  Future<void> _loadUserCommunityPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final communities = await CommunityService.fetchUserCommunities();

      if (communities.isEmpty) {
        throw Exception("Você não está inscrito em nenhuma comunidade.");
      }

      final List<CommunityPostModel> posts = [];

      for (var community in communities) {
        final communityPosts = await CommunityService.fetchCommunityPosts(community.id);
        posts.addAll(communityPosts);
      }

      setState(() {
        allCommunityPosts = posts;
      });
    } catch (error) {
      setState(() {
        errorMessage = "Erro ao carregar posts das comunidades: $error";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CreateCommunityPostWidget (
          onPostCreated: _loadUserCommunityPosts,
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
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : allCommunityPosts.isEmpty
          ? const Center(
        child: Text(
          "Sem publicações no momento.",
          style: TextStyle(color: Colors.white),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: PostListWidget (
          posts: allCommunityPosts,
          onReact: (postId, reactionType) {
            print("Reagiu com $reactionType no post $postId");
          },
          onComment: (postId) {
            print("Comentou no post $postId");
          },
          onShare: (postId) {
            print("Compartilhou o post $postId");
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePostModal,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
