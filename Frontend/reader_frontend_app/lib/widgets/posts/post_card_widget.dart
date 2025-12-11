import 'package:flutter/material.dart';
import '/models/post_model.dart';
import '/models/community_post_model.dart';

class PostCardWidget extends StatelessWidget {
  final dynamic post; // Pode ser PostModel ou CommunityPostModel
  final void Function(int postId, String reactionType) onReact;
  final void Function(int postId) onComment;
  final void Function(int postId) onShare;

  const PostCardWidget({
    required this.post,
    required this.onReact,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  int get postId => post is PostModel ? post.id : (post as CommunityPostModel).id;
  String get username => post is PostModel ? post.username : (post as CommunityPostModel).username;
  String get content => post is PostModel ? post.content : (post as CommunityPostModel).content;
  int get numberOfReactions => post is PostModel ? post.numberOfReactions : (post as CommunityPostModel).numberOfReactions;
  int get numberOfComments => post is PostModel ? post.numberOfComments : (post as CommunityPostModel).numberOfComments;
  int get numberOfReposts => post is PostModel ? post.numberOfReposts : (post as CommunityPostModel).numberOfReposts;
  String? get communityName => post is CommunityPostModel ? (post as CommunityPostModel).communityName : null;


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3E2F51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (communityName != null) // Exibe o nome da comunidade, se disponível
            Text(
              "Community: $communityName",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            "by: @$username",
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite, color: Colors.red, size: 16),
                    onPressed: () => onReact(postId, 'like'),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "$numberOfReactions",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.comment, color: Colors.grey, size: 16),
                    onPressed: () => onComment(postId),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "$numberOfComments",
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.repeat, color: Colors.grey, size: 16),
                    onPressed: () => onShare(postId),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "$numberOfReposts",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {
                  // Adicione lógica, se necessário
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
