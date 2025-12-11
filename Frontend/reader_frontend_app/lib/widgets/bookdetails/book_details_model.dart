import '/dtos/search_book_dto.dart';

enum BookDetailsAction {
  addToLibrary,
  reviewBook,
}

class BookDetailsModel {
  final SearchBookDto book;
  final BookDetailsAction action;

  BookDetailsModel({required this.book, required this.action});
}
