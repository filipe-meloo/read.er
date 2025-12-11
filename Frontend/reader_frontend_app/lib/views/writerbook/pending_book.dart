import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:reader_frontend_app/models/writer_book.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/services/author_service.dart';
import 'package:reader_frontend_app/services/config.dart';

import '../../widgets/navigation_bars/bottom_navigation_bar_widget.dart';

class PendingBooks extends m.StatefulWidget {
  const PendingBooks({super.key});

  @override
  m.State<PendingBooks> createState() => _ImagePageState();
}

class _ImagePageState extends m.State<PendingBooks> {
  int currentIndex = 2; // Define o índice atual como a página atual (PendingBooks)
  late Future<List<WriterBook>> imagesFuture;
  get isReader => false;

  @override
  void initState() {
    super.initState();
    imagesFuture = AutorService.fetchPendingBooks();
  }

  void _deleteBook(int id) {
    setState(() {
      imagesFuture = AutorService.deleteBook(id).then((_) => AutorService.fetchPendingBooks());
    });
  }

  @override
  m.Widget build(m.BuildContext context) {
    // Obtém o tamanho da tela
    final screenSize = MediaQuery.of(context).size;

    return m.Scaffold(
      backgroundColor: const m.Color(0xFF2C1B3A),
      appBar: m.AppBar(
        backgroundColor: const m.Color(0xFF2C1B3A),
        title: const m.Text(
          "Livros Pendentes",
          style: m.TextStyle(color: m.Colors.white),
        ),
        leading: IconButton(
          icon: const m.Icon(m.Icons.arrow_back, color: m.Colors.white),
          onPressed: () {
            m.Navigator.pop(context); // Volta para a tela anterior
          },
        ),
      ),
      body: m.Padding(
        padding: const m.EdgeInsets.all(8.0),
        child: m.FutureBuilder<List<WriterBook>>(
          future: imagesFuture,
          builder: (context, booksSnapshot) {
            if (booksSnapshot.connectionState == m.ConnectionState.waiting) {
              return const m.Center(child: m.CircularProgressIndicator());
            } else if (booksSnapshot.hasError) {
              return m.Center(
                child: m.Text(
                  'Erro ao carregar os livros: ${booksSnapshot.error}',
                  style: const m.TextStyle(color: m.Colors.red, fontSize: 16),
                ),
              );
            } else if (!booksSnapshot.hasData || booksSnapshot.data!.isEmpty) {
              return const m.Center(
                child: m.Text(
                  'Nenhum livro encontrado.',
                  style: m.TextStyle(fontSize: 16, color: m.Colors.white),
                ),
              );
            }

            final books = booksSnapshot.data!;

            return m.GridView.builder(
              gridDelegate: m.SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenSize.width > 600
                    ? 4 // Tablets e telas maiores
                    : screenSize.width > 400
                        ? 3 // Telas médias
                        : 2, // Smartphones pequenos
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.65, // Aspecto ajustado para imagens e botões
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return _buildBookCard(book, screenSize);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: isReader
          ? BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTabSelected: (index) {
          setState(() {
            currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/library');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/community');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/AutorHomePage');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/marketplace');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/search');
              break;
          }
        },
        isReader: true,
      )
          : null, // Oculta a barra de navegação se não for leitor.
    );
  }

  m.Widget _buildBookCard(WriterBook book, Size screenSize) {
    final encodedImageUrl = Uri.encodeComponent(
        'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api');
    final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return m.FutureBuilder<Map<String, String>>(
      future: AuthProvider.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == m.ConnectionState.waiting) {
          return const m.Center(child: m.CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const m.Icon(m.Icons.broken_image, size: 50);
        }

        return m.Column(
          children: [
            m.Card(
              color: const m.Color(0xFF3A2D58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: m.Image.network(
                coverUrl,
                headers: snapshot.data,
                fit: m.BoxFit.cover,
                height: screenSize.width > 600 ? 180 : 150, // Imagem maior em tablets
                errorBuilder: (context, error, stackTrace) {
                  return m.Icon(m.Icons.broken_image, size: 50);
                },
              ),
            ),
            m.TextButton.icon(
              onPressed: () => _deleteBook(book.id),
              icon: const m.Icon(m.Icons.delete, color: m.Colors.red),
              label: const m.Text('Excluir', style: m.TextStyle(color: m.Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
