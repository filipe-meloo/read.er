import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import '../services/config.dart';
import '/dtos/search_book_dto.dart';
import '/services/personal_library_service.dart';
import '/widgets/bookdetails/add_to_library_button.dart';

class BookDetailsPage extends StatelessWidget {
  final String isbn;
  final bool fromPersonalLibrary;
  final bool fromSearch;


  const BookDetailsPage({super.key, required this.isbn, this.fromPersonalLibrary = false, this.fromSearch = false});

  Widget buildBookCoverForDetails(BuildContext context, String volumeId) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=$volumeId&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    final coverUrl =
        '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return FutureBuilder<Map<String, String>>(
      future: AuthProvider.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image, size: 100, color: Colors.grey);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            coverUrl,
            headers: snapshot.data,
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.4,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.broken_image, size: 100, color: Colors.grey);
            },
          ),
        );
      },
    );
  }

  Widget buildAverageRating(BuildContext context, String isbn) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PersonalLibraryService.fetchBookRatings(isbn), // Atualizado para usar o ISBN
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text(
            'Ainda sem avaliações',
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          );
        }

        final data = snapshot.data!;
        final double averageRating = (data['averageRating'] ?? 0).toDouble();

        if (averageRating == 0) {
          return Text(
            'Ainda sem avaliações',
            style: TextStyle(color: Colors.grey[300], fontSize: 14),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        );
      },
    );
  }


  void _openReviewModal(BuildContext context, String volumeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController commentController = TextEditingController();
        int rating = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Avaliar Livro'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dê uma nota entre 1 e 5:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Comentário',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selecione uma nota para o livro.')),
                      );
                      return;
                    }

                    try {
                      await PersonalLibraryService.submitReview(
                        isbn: volumeId,
                        rating: rating,
                        comment: commentController.text.trim(),
                      );
                      Navigator.of(context).pop(); // Fecha o modal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Avaliação enviada com sucesso!')),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao enviar avaliação: $error')),
                      );
                    }
                  },
                  child: Text('Enviar Avaliação'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0F29),
      body: FutureBuilder<SearchBookDto>(
        future: PersonalLibraryService.fetchBookDetailsByIsbn(isbn),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao buscar os detalhes do livro.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Livro não encontrado.'));
          }

          final book = snapshot.data!;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0F29),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Expanded(
                            child: Text(
                              book.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, color: Colors.white),
                            onPressed: () {
                              // Favoritar ação
                            },
                          ),
                        ],
                      ),
                      Text(
                        'by ${book.author}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Capa do Livro
                buildBookCoverForDetails(context, book.volumeId),
                const SizedBox(height: 8),
                // Avaliação Média
                buildAverageRating(context, book.volumeId),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    color: Colors.grey[400],
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Sinopse',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Sinopse
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        book.description ?? 'Descrição não disponível.',
                        style:  TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Botão de ação (Adicionar à Biblioteca ou Avaliar)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: fromPersonalLibrary
                      ? ElevatedButton(
                    onPressed: () => _openReviewModal(context, book.volumeId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Avaliar Livro',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                      : fromSearch
                      ? AddToLibraryButton(book: book)
                      : Container(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
