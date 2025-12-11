import 'package:flutter/material.dart';
import 'post_card_widget.dart';

class PostListWidget extends StatelessWidget {
  final List<dynamic> posts; // Aceita PostModel ou CommunityPostModel
  final void Function(int postId, String reactionType) onReact;
  final void Function(int postId) onComment;
  final void Function(int postId) onShare;

  const PostListWidget({
    required this.posts,
    required this.onReact,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'Sem publicações no momento.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Margem nas laterais e no topo/inferior
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCardWidget(
            post: post,
            onReact: onReact,
            onComment: onComment,
            onShare: onShare,
          );
        },
      ),
    );
  }

}
