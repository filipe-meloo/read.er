import 'package:flutter/material.dart';
import '/models/comment_model.dart';
import '/services/post_service.dart';

class CommentsModal extends StatefulWidget {
  final int postId;
  final VoidCallback? onCommentAdded;

  const CommentsModal({super.key, required this.postId, this.onCommentAdded});

  @override
  _CommentsModalState createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  List<CommentModel> comments = [];
  bool isLoading = true;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final fetchedComments = await PostService.fetchComments(widget.postId);
      setState(() {
        comments = fetchedComments;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar comentários: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final content = commentController.text;
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O comentário não pode estar vazio.')),
      );
      return;
    }

    try {
      await PostService.commentOnPost(widget.postId, content);
      commentController.clear();

      setState(() {
        comments.add(CommentModel(
          id: comments.length + 1,
          postId: widget.postId,
          userId: 1,
          content: content,
          createdAt: DateTime.now(),
          username: 'Você',
        ));
      });

      if (widget.onCommentAdded != null) {
        widget.onCommentAdded!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comentário adicionado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar comentário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1E0F29),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Comentários',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.purple))
                : comments.isEmpty
                ? Center(
              child: Text(
                'Ainda não há comentários.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.separated(
              itemCount: comments.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[700]),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Text(
                      comment.username?.substring(0, 1) ?? '?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    comment.username ?? 'Usuário desconhecido',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    comment.content,
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    comment.createdAt != null
                        ? comment.createdAt.toLocal().toString().split(' ')[0]
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Escreva um comentário...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFF2C1B3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.purple,
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: _addComment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
