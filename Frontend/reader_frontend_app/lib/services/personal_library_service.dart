import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import '../dtos/search_book_dto.dart';
import 'auth_service.dart';
import '../models/library_book.dart';
import '../services/config.dart';
import '../enumeracoes/status.dart';

class PersonalLibraryService {
  static Future<void> addBookToLibrary(
      String volumeId, String title, String status, DateTime? dateRead) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token não encontrado.");
      }

      final response = await http.post(
        Uri.parse('$BASE_URL/api/PersonalLibrary/addToLibrary'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "dateRead": dateRead?.toIso8601String(),
          "volumeId": volumeId,
          "Title": title,
          "Status": status,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Falha ao adicionar livro à biblioteca: ${response.body}');
      }
    } catch (e) {
      print("Erro ao adicionar livro à biblioteca: $e");
      rethrow;
    }
  }

  static String buildBookCoverUrl(String volumeId) {
    final encodedImageUrl = Uri.encodeComponent(
      'http://books.google.com/books/content?id=$volumeId&printsec=frontcover&img=1&zoom=1&source=gbs_api',
    );
    return encodedImageUrl;
  }

  static Future<SearchBookDto> fetchBookDetailsByIsbn(String isbn) async {
    final url =
        '$BASE_URL/api/PersonalLibrary/getBookDetails?isbn=$isbn';

    try {
      final headers = await AuthProvider.getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SearchBookDto(
          isbn: data['isbn'],
          title: data['title'],
          author: data['author'],
          coverUrl: data['coverUrl'] ?? '',
          description: data['description'] ?? 'Descrição não disponível.',
          volumeId: data['volumeId'],
        );
      } else if (response.statusCode == 401) {
        throw Exception('Não autorizado. Verifique o token JWT.');
      } else {
        throw Exception(
            'Erro ao buscar os detalhes do livro. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  static Future<bool> isPromoted(String isbn) async {
    try {
      print("Iniciando verificação de promoção para ISBN: $isbn");

      final response = await http.get(
        Uri.parse('$BASE_URL/api/WriterBooks/isPromoted/$isbn'),
        headers: await AuthProvider.getHeaders(),
      );

      print("Resposta da API (status code): ${response.statusCode}");
      print("Corpo da resposta: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print("Resultado decodificado: $result");

        // Verifica se o resultado é do tipo bool
        if (result is bool) {
          print("Retornando resultado como bool: $result");
          return result;
        }

        // Trata valores inesperados como `2`
        if (result is int) {
          print("Valor numérico recebido: $result. Considerando como não promovido.");
          return result == 1; // Supondo que `1` signifique promovido e `2` não promovido.
        }

        throw Exception("Resposta inesperada da API: $result");
      } else {
        throw Exception("Erro na API: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao verificar promoção para ISBN $isbn: $e");
      return false; // Assume que não está promovido em caso de erro
    }
  }



  static Future<int> fetchBooksReadedCountForUser(int userId) async {
    final url = Uri.parse("$BASE_URL/$userId/booksReadedCount");
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count']; // A API deve retornar algo como {"count": 10}
      } else {
        throw Exception(
            "Erro ao buscar livros lidos para o usuário $userId: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Erro ao buscar livros lidos para o usuário $userId: $e");
    }
  }

  static Future<List<LibraryBook>> fetchCurrentlyReadingBooks() async {
    return _fetchBooks('/list-user-currentread-books');
  }

  static Future<List<LibraryBook>> fetchToBeReadBooks() async {
    return _fetchBooks('/list-user-tbr-books');
  }

  static Future<List<LibraryBook>> fetchReadBooks() async {
    return _fetchBooks('/list-user-readed-books');
  }

  static Future<Map<String, dynamic>> fetchBookRatings(String isbn) async {
    final response = await http.get(
      Uri.parse(
          '$BASE_URL/api/Review/bookRatingAverage?isbn=$isbn'),
      headers: await AuthProvider.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar avaliações: ${response.body}');
    }
  }

  static Future<void> updateBookStatus({
    required String isbn,
    required Status status,
    required int pagesRead,
  }) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token não encontrado.");
      }

      final response = await http.put(
        Uri.parse('$BASE_URL/api/PersonalLibrary/update'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "isbn": isbn,
          "status": status
              .toString()
              .split('.')
              .last, // Transforma o enum para string
          "pagesRead": pagesRead,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Falha ao atualizar o status do livro: ${response.body}');
      }
    } catch (e) {
      print("Erro ao atualizar o status do livro: $e");
      rethrow;
    }
  }

  static Future<void> submitReview({
    required String isbn,
    required int rating,
    required String comment,
  }) async {
    final url = '$BASE_URL/api/Review/rateBook';
    final headers = await AuthProvider.getHeaders();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'isbn': isbn,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar avaliação: ${response.reasonPhrase}');
    }
  }

  static Future<List<LibraryBook>> _fetchBooks(String endpoint) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token não encontrado.");
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/api/PersonalLibrary$endpoint'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((book) => LibraryBook.fromJson(book)).toList();
      } else {
        throw Exception("Failed to load books");
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }
}
