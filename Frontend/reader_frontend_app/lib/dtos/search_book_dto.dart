import '../models/library_book.dart';

class SearchBookDto {
  final String volumeId;
  final String isbn;
  final String title;
  final String author;
  final String coverUrl;
  final String description;

  SearchBookDto({
    required this.volumeId,
    required this.title,
    required this.isbn,
    required this.author,
    required this.coverUrl,
    required this.description,
  });


  factory SearchBookDto.fromLibraryBook(LibraryBook book) {
    return SearchBookDto(
      title: book.title,
      volumeId: book.volumeId,
      isbn: book.isbn.trim(),
      author: book.author,
      description: book.description,
      coverUrl: book.coverUrl,
    );
  }
}
