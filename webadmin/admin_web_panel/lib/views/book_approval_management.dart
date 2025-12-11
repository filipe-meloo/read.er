import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class BookApprovalManagementView extends StatefulWidget {
  @override
  _BookApprovalManagementViewState createState() =>
      _BookApprovalManagementViewState();
}

class _BookApprovalManagementViewState
    extends State<BookApprovalManagementView> {
  late Future<List<dynamic>> _futureBooks;

  @override
  void initState() {
    super.initState();
    _futureBooks = AdminService.fetchBooksForApproval();
  }

  void _refreshBooks() {
    setState(() {
      _futureBooks = AdminService.fetchBooksForApproval();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestão de Aprovações de Livros")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureBooks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro: ${snapshot.error}",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return Center(
              child: Text(
                "Nenhum livro pendente de aprovação.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(book['title'] ?? 'Título indisponível'),
                  subtitle: Text("ID: ${book['id']}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "approve") {
                        try {
                          await AdminService.approveBook(book['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Livro aprovado!")),
                          );
                          _refreshBooks(); // Atualiza a lista após a aprovação
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erro ao aprovar livro: $error"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else if (value == "reject") {
                        try {
                          await AdminService.rejectBook(
                            bookId: book['id'],
                            reason: "Razão fornecida",
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Livro rejeitado!")),
                          );
                          _refreshBooks(); // Atualiza a lista após a rejeição
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erro ao rejeitar livro: $error"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "approve",
                        child: Text("Aprovar Livro"),
                      ),
                      PopupMenuItem(
                        value: "reject",
                        child: Text("Rejeitar Livro"),
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
