import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';

import '../../services/config.dart';

class BookTile extends StatelessWidget {
  final String volumeId;
  final String title;
  final String author;
  final String progressInfo;
  final double progressPercentage;
  final VoidCallback onEditPages;

  const BookTile({super.key, 
    required this.volumeId,
    required this.title,
    required this.author,
    required this.progressInfo,
    required this.progressPercentage,
    required this.onEditPages,
  });

  /// Função para gerar o URL codificado da capa
  String getEncodedCoverUrl(String volumeId) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=$volumeId&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    return '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';
  }

  Widget buildBookCover(String volumeId) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=$volumeId&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return FutureBuilder<Map<String, String>>(
      future: AuthProvider.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image, size: 50);
        }

        return Image.network(
          coverUrl,
          headers: snapshot.data, // Passa os cabeçalhos com o token JWT
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: 50);
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final coverUrl = getEncodedCoverUrl(volumeId);

    return FutureBuilder<Map<String, String>>(
      future: AuthProvider.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.broken_image, size: 50);
        }

        return ListTile(
          leading: Image.network(
            coverUrl,
            headers: snapshot.data,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.broken_image, size: 50);
            },
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(author),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.purple),
                onPressed: onEditPages,
              ),
              SizedBox(
                width: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(progressInfo),
                    LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.grey[300],
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
