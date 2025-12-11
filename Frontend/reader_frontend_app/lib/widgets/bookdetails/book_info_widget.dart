import 'package:flutter/material.dart';
import '/dtos/search_book_dto.dart';

class BookInfoWidget extends StatelessWidget {
  final SearchBookDto book;

  const BookInfoWidget({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          book.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'by ${book.author}',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
