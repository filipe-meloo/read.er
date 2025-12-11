import 'package:flutter/material.dart';
import '../../services/config.dart';
import '/dtos/search_book_dto.dart';

class BookCoverWidget extends StatelessWidget {
  final SearchBookDto book;

  const BookCoverWidget({super.key, required this.book, required String imageUrl});

  @override
  Widget build(BuildContext context) {
    final encodedImageUrl = Uri.encodeComponent(book.coverUrl);
    final coverUrl =
        '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        coverUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image,
          size: 100,
          color: Colors.grey,
        ),
      ),
    );
  }
}
