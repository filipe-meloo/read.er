import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'auth_service.dart';
import 'package:reader_frontend_app/dtos/search_book_dto.dart';
import '../services/config.dart';

class BookService {

  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  static Future<Map<String, dynamic>?> fetchBookDetails(String isbn) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token não encontrado.");
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/api/Books/details/$isbn'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch book details for ISBN: $isbn");
      }
    } catch (e) {
      print("Error fetching book details: $e");
      return null;
    }
  }

  static Future<void> fetchBookCover(String imageUrl) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token não encontrado.");
      }

      final response = await http.get(
        Uri.parse(
            '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$imageUrl'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch book cover.");
      }
    } catch (e) {
      print("Error fetching book cover: $e");
    }
  }

 Future<List<SearchBookDto>> fetchRecommendations() async {
  final url = Uri.parse('$BASE_URL/api/PersonalLibrary/recommendations');

  try {
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        return SearchBookDto(
          volumeId: item['volumeId'],
          isbn: item['isbn'],
          title: item['title'],
          author: item['author'],
          coverUrl: item['coverUrl'],
          description: item['description'] ?? 'Descrição não disponível',
        );
      }).toList();
    } else {
      throw Exception('Erro ao buscar recomendações: ${response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Erro ao buscar recomendações: $e');
  }
}


  static Future<String?> getTitleByISBN(String isbn) async {
    final url = Uri.parse('$baseUrl?q=isbn:$isbn');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0]['volumeInfo']['title'];
        }
        return null;
      } else {
        throw Exception('Erro ao buscar título do livro');
      }
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

  static Future<String?> getISBNByTitle(String title) async {
    final url = Uri.parse('$baseUrl?q=intitle:$title');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          if (volumeInfo['industryIdentifiers'] != null) {
            for (var identifier in volumeInfo['industryIdentifiers']) {
              if (identifier['type'] == 'ISBN_13') {
                return identifier['identifier'];
              }
            }
            // Se não encontrar ISBN-13, retorna o ISBN-10 se disponível
            for (var identifier in volumeInfo['industryIdentifiers']) {
              if (identifier['type'] == 'ISBN_10') {
                return identifier['identifier'];
              }
            }
          }
        }
        return null; // Caso o ISBN não seja encontrado
      } else {
        throw Exception('Erro ao buscar ISBN do livro');
      }
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

}