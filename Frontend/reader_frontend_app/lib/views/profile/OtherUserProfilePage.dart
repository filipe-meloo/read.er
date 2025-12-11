import 'package:flutter/material.dart';
import '../../widgets/posts/comments_modal.dart';
import '../../widgets/posts/post_list_widget.dart';
import '../../services/user_profile_service.dart';
import '../../services/post_service.dart';
import '/models/post_model.dart';
import '/headers/user_profile_header.dart';

class OtherUserProfilePage extends StatefulWidget {
  final int userId;

  const OtherUserProfilePage({super.key, required this.userId});

  @override
  _OtherUserProfilePageState createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  Map<String, dynamic>? userProfileData;
  List<PostModel> userPosts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOtherUserProfileData();
  }

  Future<void> _loadOtherUserProfileData() async {
    try {
      final profileData = await UserProfileService.fetchOtherUserProfile(widget.userId);
      final posts = await PostService.fetchPostsForUser(widget.userId);

      setState(() {
        userProfileData = profileData;
        userPosts = posts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar o perfil do usuário: $e";
        isLoading = false;
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
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    if (userProfileData == null) {
      return const Center(
        child: Text(
          "Nenhum dado de usuário encontrado.",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple,
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfileData!['username'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildStatistic(Icons.book, userProfileData!['booksReadedCount'].toString(), "Books"),
                        const SizedBox(width: 16),
                        _buildStatistic(Icons.people, userProfileData!['friendsCount'].toString(), "Friends"),
                        const SizedBox(width: 16),
                        _buildStatistic(Icons.groups, userProfileData!['communitiesCount'].toString(), "Communities"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white, thickness: 1, height: 32),
          const SizedBox(height: 16),

          // User Posts Section
          const Text(
            "Posts",
            style: TextStyle(
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
              onReact: (postId, reactionType) => _reactToPost(postId, reactionType),
              onComment: (postId) => _commentOnPost(postId),
              onShare: (postId) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(IconData icon, String value, String label) {
    return Column(
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
    );
  }

  void _reactToPost(int postId, String reactionType) async {
    try {
      await PostService.reactToPost(postId, reactionType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Você reagiu com $reactionType ao post $postId")),
      );
      _loadOtherUserProfileData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao reagir ao post: $e")),
      );
    }
  }

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
}
