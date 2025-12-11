import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/services/book_service.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'dart:convert';
import '../../widgets/bookdetails/book_details_model.dart';
import '/dtos/search_book_dto.dart';
import '../../widgets/navigation_bars/bottom_navigation_bar_widget.dart';
import 'package:reader_frontend_app/headers/search_header.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchBookDto> searchResults = [];
  List<SearchBookDto> recommendedBooks = [];
  bool isLoading = false;
  bool isRecommendationsLoading = false;
  String? errorMessage;

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        errorMessage = "Por favor, insira o título do livro para pesquisar.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      searchResults.clear();
      errorMessage = null;
    });

    final url = Uri.parse('$BASE_URL/api/Search/searchByTitle?title=$query');

    try {
      final response = await http.get(url, headers: await AuthProvider.getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          searchResults = data.map((item) {
            return SearchBookDto(
              volumeId: item['volumeId'],
              isbn: item['isbn'],
              title: item['title'],
              author: item['author'],
              coverUrl: item['coverUrl'] ?? '',
              description: item['description'] ?? 'Descrição não disponível',
            );
          }).toList();
          if (searchResults.isEmpty) {
            errorMessage = "Nenhum livro encontrado.";
          }
        });
      } else {
        setState(() {
          errorMessage = 'Erro ao buscar livros: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao buscar livros: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      isRecommendationsLoading = true;
    });

    try {
      final bookService = BookService();
      final recommendations = await bookService.fetchRecommendations();
      setState(() {
        recommendedBooks = recommendations;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar recomendações: $e';
      });
    } finally {
      setState(() {
        isRecommendationsLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations(); // Carrega as recomendações assim que a página é carregada
  }

  @override
  Widget build(BuildContext context) {
    // Definir o número de colunas para recomendações dependendo da largura da tela
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final itemWidth = isLargeScreen ? 150.0 : 100.0; // Largura do item
    final itemHeight = isLargeScreen ? 220.0 : 150.0; // Altura do item

    return Scaffold(
      backgroundColor: Color(0xFF2C1B3A),
      body: Column(
        children: [
          SearchHeader(
            searchController: _searchController,
            onSearch: _searchBooks,
            onBackPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isRecommendationsLoading
                ? Center(child: CircularProgressIndicator())
                : recommendedBooks.isEmpty
                    ? Center(
                        child: Text(
                          errorMessage ?? "Nenhuma recomendação disponível.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recomendações',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Usando ListView para a navegação horizontal
                          SizedBox(
                            height: itemHeight, // Tamanho do item baseado na tela
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal, // Navegação horizontal
                              itemCount: recommendedBooks.length,
                              itemBuilder: (context, index) {
                                final book = recommendedBooks[index];
                                final encodedImageUrl = Uri.encodeComponent(
                                  'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api'
                                );
                                final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/book-details/${book.isbn}',
                                      arguments: {
                                        'book': book,
                                        'action': BookDetailsAction.addToLibrary,
                                      },
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        FutureBuilder<Map<String, String>>(
                                          future: AuthProvider.getHeaders(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            } else if (snapshot.hasError || !snapshot.hasData) {
                                              return Icon(Icons.broken_image);
                                            }

                                            return Image.network(
                                              coverUrl,
                                              headers: snapshot.data,
                                              width: itemWidth, // Largura responsiva
                                              height: itemHeight * 0.7, // Altura ajustada para caber na grade
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          book.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : searchResults.isEmpty
                      ? Center(
                          child: Text(
                            errorMessage ?? "Nenhum livro encontrado.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final book = searchResults[index];
                            final encodedImageUrl = Uri.encodeComponent(
                              'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api'
                            );
                            final coverUrl = '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

                            return ListTile(
                              leading: FutureBuilder<Map<String, String>>(
                                future: AuthProvider.getHeaders(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError || !snapshot.hasData) {
                                    return Icon(Icons.broken_image);
                                  }

                                  return Image.network(
                                    coverUrl,
                                    headers: snapshot.data,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                                  );
                                },
                              ),
                              title: Text(
                                book.title,
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                book.author,
                                style: TextStyle(color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/book-details/${book.isbn}',
                                  arguments: {
                                    'book': book,
                                    'action': BookDetailsAction.addToLibrary,
                                  },
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: 4,
        onTabSelected: (index) {
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
              Navigator.pushReplacementNamed(context, '/store');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/search');
              break;
          }
        }, isReader: true,
      ),
    );
  }
}
