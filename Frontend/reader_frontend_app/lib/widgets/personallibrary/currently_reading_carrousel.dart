import 'package:flutter/material.dart';
import '../../services/config.dart';
import '../bookdetails/book_details_model.dart';
import '/models/library_book.dart';
import '/services/personal_library_service.dart';
import '/dtos/search_book_dto.dart';


class CurrentlyReadingCarousel extends StatelessWidget {
  final List<LibraryBook> books;
  final Future<Map<String, String>> Function() getHeaders;
  final Future<void> Function() fetchBooks;
  final void Function(LibraryBook book)? onAccept; // Add onAccept parameter

  const CurrentlyReadingCarousel({super.key, 
    required this.books,
    required this.getHeaders,
    required this.fetchBooks,
    this.onAccept, // Initialize onAccept
  });

  // Widget for the book image with drag-and-drop support
  Widget buildBookCover(BuildContext context, LibraryBook book) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return Draggable<LibraryBook>(
      data: book, // Pass the book as draggable data
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
        future: getHeaders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Icon(Icons.broken_image, size: 50);
          }

          return GestureDetector(
            onTap: () => _updatePagesRead(context, book), // Update pages read on tap
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                coverUrl,
                headers: snapshot.data,
                width: 80,
                height: 120,
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

  // Update the number of pages read
  void _updatePagesRead(BuildContext context, LibraryBook book) async {
    final pagesController = TextEditingController(text: book.pagesRead.toString() ?? '0');
    final newPagesRead = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Pages Read"),
          content: TextField(
            controller: pagesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter the number of pages read"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, int.tryParse(pagesController.text));
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );

    if (newPagesRead != null) {
      try {
        await PersonalLibraryService.updateBookStatus(
          isbn: book.isbn,
          status: book.status, // Ensure status is accepted by the backend
          pagesRead: newPagesRead,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pages read updated!')),
        );
        await fetchBooks(); // Reload books
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pages: $e')),
        );
      }
    }
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
    return DragTarget<LibraryBook>(
      onAcceptWithDetails: (details) => onAccept!(details.data), // Pass the onAccept function
      builder: (context, candidateData, rejectedData) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currently Reading",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final progressPercentage = (book.pagesRead / book.totalPages).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book image with drag functionality
                        buildBookCover(context, book),
                        SizedBox(width: 16),
                        // Book details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToBookDetails(context, book),
                                child: Text(
                                  book.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                book.description.length > 100
                                    ? '${book.description.substring(0, 100)}...'
                                    : book.description,
                                style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _updatePagesRead(context, book),
                                child: Text(
                                  "${book.pagesRead}/${book.totalPages} pages",
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${(progressPercentage * 100).toStringAsFixed(0)}%",
                                style: TextStyle(color: Colors.grey[300], fontSize: 12),
                              ),
                              SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progressPercentage,
                                backgroundColor: Colors.grey,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8), // Space before horizontal line
                              Divider(color: Colors.white, thickness: 1), // Horizontal line
                            ],
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
      },
    );
  }
}

