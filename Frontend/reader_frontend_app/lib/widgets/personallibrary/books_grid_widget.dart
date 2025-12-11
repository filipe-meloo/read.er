import 'package:flutter/material.dart';
import '../../services/config.dart';
import '/models/library_book.dart';
import '/dtos/search_book_dto.dart';
import '/widgets/bookdetails/book_details_model.dart';

class BooksGridWidget extends StatefulWidget {
  final String title;
  final List<LibraryBook> books;
  final Future<Map<String, String>> Function() getHeaders;
  final void Function(LibraryBook book)? onAccept;

  const BooksGridWidget({super.key, 
    required this.title,
    required this.books,
    required this.getHeaders,
    this.onAccept,
  });

  @override
  _BooksGridWidgetState createState() => _BooksGridWidgetState();
}

class _BooksGridWidgetState extends State<BooksGridWidget> {
  bool showAllBooks = false;
  final double bookSpacing = 8.0;

  Widget buildBookCover(BuildContext context, LibraryBook book) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return Draggable<LibraryBook>(
      data: book,
      feedback: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            coverUrl,
            width: 80,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      child: FutureBuilder<Map<String, String>>(
        future: widget.getHeaders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Icon(Icons.broken_image, size: 50);
          }

          return GestureDetector(
            onTap: () => _navigateToBookDetails(context, book),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: Image.network(
                coverUrl,
                headers: snapshot.data,
                width: 100,
                height: 89.69,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 50);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToBookDetails(BuildContext context, LibraryBook book) {
    Navigator.pushNamed(
      context,
      '/book-details/${book.isbn}',
      arguments: {
        'book': SearchBookDto.fromLibraryBook(book),
        'action': BookDetailsAction.reviewBook, // Especifique a ação correta
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int booksPerRow = screenWidth > 800
        ? 6
        : screenWidth > 600
        ? 4
        : 2;

    final booksToDisplay = showAllBooks
        ? widget.books
        : widget.books.take(booksPerRow * 2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          DragTarget<LibraryBook>(
            onAcceptWithDetails: (book) {
              if (widget.onAccept != null) {
                widget.onAccept!(book as LibraryBook);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF715883),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: booksPerRow,
                      crossAxisSpacing: bookSpacing,
                      mainAxisSpacing: bookSpacing,
                      children: booksToDisplay.map((book) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildBookCover(context, book),
                            SizedBox(height: 4),
                            Text(
                              book.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              book.author,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    if (widget.books.length > booksPerRow * 2)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showAllBooks = !showAllBooks;
                            });
                          },
                          child: Text(
                            showAllBooks
                                ? "See less"
                                : "See ${widget.books.length - booksPerRow * 2} more",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
