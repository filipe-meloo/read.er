import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class PostManagementView extends StatefulWidget {
  @override
  _PostManagementViewState createState() => _PostManagementViewState();
}

class _PostManagementViewState extends State<PostManagementView> {
  late Future<List<dynamic>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _futurePosts = AdminService.fetchReportedPosts();
  }

  void _refreshPosts() {
    setState(() {
      _futurePosts = AdminService.fetchReportedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestão de Posts")),
      body: FutureBuilder<List<dynamic>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Erro: ${snapshot.error}", style: TextStyle(color: Colors.red, fontSize: 16)),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Text(
                "Nenhum post reportado.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(post['conteudo'] ?? 'Conteúdo indisponível'),
                  subtitle: Text("ID: ${post['id']}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "mark_inappropriate") {
                        try {
                          await AdminService.markPostAsInappropriate(post['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Post marcado como impróprio!")),
                          );
                          _refreshPosts(); // Atualiza a lista de posts
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro: $error")),
                          );
                        }
                      } else if (value == "delete") {
                        try {
                          await AdminService.deletePost(post['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Post excluído!")),
                          );
                          _refreshPosts(); // Atualiza a lista de posts
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro: $error")),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "mark_inappropriate",
                        child: Text("Marcar como impróprio"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text("Excluir Post"),
                      ),
                    ],
                    icon: Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
