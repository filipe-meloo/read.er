import 'package:flutter/material.dart';
import '/dtos/search_book_dto.dart';

class BookDetailsHeader extends StatelessWidget implements PreferredSizeWidget {
  final SearchBookDto book;

  const BookDetailsHeader({super.key, required this.book});

  @override
  Size get preferredSize => Size.fromHeight(120); // Altura dinâmica para o header

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E0F29),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.bookmark_outline, color: Colors.white),
                  onPressed: () {
                    // Lógica para marcar o livro
                  },
                ),
              ],
            ),
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 56), // Alinhado com o título
              child: Text(
                'by ${book.author}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
