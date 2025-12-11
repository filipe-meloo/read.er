import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/services/personal_library_service.dart';
import '../../models/writer_book.dart';
import '../../services/config.dart';
import '/services/author_service.dart';

class AuthorBookDetailsPage extends StatelessWidget {
  final WriterBook book;

  const AuthorBookDetailsPage({super.key, required this.book});

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

  Widget buildPromoteButton(BuildContext context, String isbn) {
    return FutureBuilder<bool>(
      future: PersonalLibraryService.isPromoted(isbn),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Erro ao verificar promoção.',
            style: TextStyle(color: Colors.red, fontSize: 14),
          );
        }

        final isPromoted = snapshot.data ?? false;

        if (isPromoted) {
          return Text(
            'O livro já foi promovido.',
            style: TextStyle(color: Colors.green, fontSize: 16),
          );
        }

        return ElevatedButton(
          onPressed: () async {
            try {
              await AutorService().promoteBook(isbn);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Livro promovido com sucesso!')),
              );
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao promover livro: $error')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Promover Livro',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0F29),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(book.title, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Book Cover
            Center(
              child: buildBookCoverForDetails(context, book.volumeId),
            ),
            const SizedBox(height: 16),
            // Book Title and Author
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'by ${book.author}',
              style: TextStyle(fontSize: 16, color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            // Promote Book Button
            buildPromoteButton(context, book.Isbn),
          ],
        ),
      ),
    );
  }
}
