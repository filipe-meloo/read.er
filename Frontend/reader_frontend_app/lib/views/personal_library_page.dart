import 'package:flutter/material.dart';
import 'package:reader_frontend_app/enumeracoes/status.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import '../widgets/personallibrary/books_grid_widget.dart';
import '../widgets/personallibrary/currently_reading_carrousel.dart';
import '/services/personal_library_service.dart';
import '/models/library_book.dart';
import '/headers/personal_library_header.dart';

class PersonalLibraryPage extends StatefulWidget {
  const PersonalLibraryPage({super.key});

  @override
  _PersonalLibraryPageState createState() => _PersonalLibraryPageState();
}

class _PersonalLibraryPageState extends State<PersonalLibraryPage> {
  List<LibraryBook> currentlyReadingBooks = [];
  List<LibraryBook> toBeReadBooks = [];
  List<LibraryBook> readBooks = [];
  bool isLoading = true;
  String errorMessage = "";
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final crBooks = await PersonalLibraryService.fetchCurrentlyReadingBooks();
      final tbrBooks = await PersonalLibraryService.fetchToBeReadBooks();
      final readBooksList = await PersonalLibraryService.fetchReadBooks();

      setState(() {
        currentlyReadingBooks = crBooks;
        toBeReadBooks = tbrBooks;
        readBooks = readBooksList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar livros: $e";
        isLoading = false;
      });
    }
  }

  void onTabSelected(int index) {
    setState(() {
      currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/library');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/community');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/marketplace');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/search');
        break;
    }
  }

  void _onAcceptBook(LibraryBook book, String newCategory) async {
    Status newStatus;
    switch (newCategory) {
      case "To Be Read":
        newStatus = Status.TBR;
        break;
      case "Currently Reading":
        newStatus = Status.CURRENT_READ;
        break;
      case "Read":
        newStatus = Status.READ;
        break;
      default:
        return;
    }

    await PersonalLibraryService.updateBookStatus(
      isbn: book.isbn,
      status: newStatus,
      pagesRead: book.pagesRead,
    );

    setState(() {
      currentlyReadingBooks.remove(book);
      toBeReadBooks.remove(book);
      readBooks.remove(book);

      switch (newStatus) {
        case Status.TBR:
          toBeReadBooks.add(book);
          break;
        case Status.CURRENT_READ:
          currentlyReadingBooks.add(book);
          break;
        case Status.READ:
          readBooks.add(book);
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${book.title} movido para $newCategory!")),
    );
  }

  void _handleAcceptBookForCategory(LibraryBook book, String category) {
    _onAcceptBook(book, category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E0F29),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: PersonalLibraryHeader(
          onProfileTap: () {
            print("Perfil clicado");
          },
          onSettingsTap: () {
            Navigator.pushNamed(context, '/profile/update');
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.red),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DragTarget<LibraryBook>(
              onAcceptWithDetails: (book) => _handleAcceptBookForCategory(book as LibraryBook, "Currently Reading"),
              builder: (context, candidateData, rejectedData) {
                return CurrentlyReadingCarousel(
                  books: currentlyReadingBooks,
                  getHeaders: AuthProvider.getHeaders,
                  fetchBooks: fetchBooks,
                  onAccept: (book) => _handleAcceptBookForCategory(book, "Currently Reading"),
                );
              },
            ),
            DragTarget<LibraryBook>(
              onAcceptWithDetails: (book) => _handleAcceptBookForCategory(book as LibraryBook, "To Be Read"),
              builder: (context, candidateData, rejectedData) {
                return BooksGridWidget(
                  title: "Your to be read",
                  books: toBeReadBooks,
                  getHeaders: AuthProvider.getHeaders,
                  onAccept: (book) => _handleAcceptBookForCategory(book, "To Be Read"),
                );
              },
            ),
            DragTarget<LibraryBook>(
              onAcceptWithDetails: (book) => _handleAcceptBookForCategory(book as LibraryBook, "Read"),
              builder: (context, candidateData, rejectedData) {
                return BooksGridWidget(
                  title: "Read",
                  books: readBooks,
                  getHeaders: AuthProvider.getHeaders,
                  onAccept: (book) => _handleAcceptBookForCategory(book, "Read"),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        backgroundColor: Color(0xFF1E0F29),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Search'),
        ],
      ),
    );
  }
}