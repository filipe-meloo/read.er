import 'package:flutter/material.dart';

import '/models/library_book.dart';
import 'book_tile.dart';

class BookCategoryWidget extends StatelessWidget {
  final String categoryTitle;
  final List<LibraryBook> books;
  final List<LibraryBook> sourceList;
  final Function(LibraryBook, String) onAccept;
  final Function(LibraryBook)? onEditPages; // Função opcional
  final bool enableEditPages; // Flag para habilitar/desabilitar edição de páginas

  const BookCategoryWidget({super.key, 
    required this.categoryTitle,
    required this.books,
    required this.sourceList,
    required this.onAccept,
    this.onEditPages,
    this.enableEditPages = true, // Por padrão, edição de páginas está habilitada
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            categoryTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        DragTarget<LibraryBook>(
          onAcceptWithDetails: (details) => onAccept(details.data, categoryTitle),
          builder: (context, candidateData, rejectedData) {
            return Column(
              children: books.map((book) {
                return Draggable<LibraryBook>(
                  data: book,
                  feedback: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: Material(
                      child: BookTile(
                        volumeId: book.volumeId,
                        title: book.title,
                        author: book.author,
                        progressInfo: '${book.pagesRead}/${book.totalPages} pages',
                        progressPercentage: book.progressPercentage,
                        onEditPages: enableEditPages
                            ? () => onEditPages?.call(book)
                            : () {}, // Passa uma função vazia quando desabilitado
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: BookTile(
                      volumeId: book.volumeId,
                      title: book.title,
                      author: book.author,
                      progressInfo: '${book.pagesRead}/${book.totalPages} pages',
                      progressPercentage: book.progressPercentage,
                      onEditPages: enableEditPages
                          ? () => onEditPages?.call(book)
                          : () {}, // Passa uma função vazia quando desabilitado
                    ),
                  ),
                  child: BookTile(
                    volumeId: book.volumeId,
                    title: book.title,
                    author: book.author,
                    progressInfo: '${book.pagesRead}/${book.totalPages} pages',
                    progressPercentage: book.progressPercentage,
                    onEditPages: enableEditPages
                        ? () => onEditPages?.call(book)
                        : () {}, // Passa uma função vazia quando desabilitado
                  ),
                );
              }).toList(),
            );
          },
        ),
        Divider(),
      ],
    );
  }
}
