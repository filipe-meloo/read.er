import 'dart:convert';
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/writer_book.dart';
import 'package:url_launcher/url_launcher.dart';



class AutorService {
  static const String baseUrl = '$BASE_URL/api/FollowAuthors';

  static Future<int> fetchFollowersCount() async {
    final url = Uri.parse('$baseUrl/NumberOfFollowers');
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody is int) {
          return responseBody;
        } else {
          throw Exception('A resposta não é um número ou lista esperada.');
        }
      } else {
        print(
            'Erro ao buscar seguidores: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Erro ao buscar seguidores: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar seguidores: $e');
      throw Exception('Erro ao buscar seguidores. Detalhes: $e');
    }
  }

  static Future<void> deleteBook(int id) async {
    final url = Uri.parse('$BASE_URL/api/WriterBooks/remove/$id');
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        print('Livro eliminado com sucesso!');
      } else {
        print(
            'Erro ao eliminar o livro: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Erro ao eliminar o livro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao eliminar o livro: $e');
      throw Exception('Erro ao eliminar o livro. Detalhes: $e');
    }
  }


Future<void> promoteBook(String isbn) async {
  final response = await http.post(
    Uri.parse('$BASE_URL/api/WriterBooks/promote/$isbn'),
    headers: {
      'Authorization': 'Bearer ${await getToken()}',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);

    if (responseData.containsKey('checkoutUrl')) {
      final checkoutUrl = responseData['checkoutUrl'];
      print("Redirecting to Stripe checkout: $checkoutUrl");

      // Redireciona o usuário para o Stripe Checkout
      if (await canLaunch(checkoutUrl)) {
        await launch(checkoutUrl);  // Isso abrirá o link no navegador
      } else {
        print('Não foi possível abrir o URL.');
      }
    } else {
      print('Erro: checkoutUrl não encontrado na resposta');
    }
  } else {
    print('Falha na promoção: ${response.body}');
  }
}




  static Future<int> getNumberOfBooks() async {
    final url = Uri.parse('$BASE_URL/api/WriterBooks/list-approved');

    final response = await http.get(
      url,
      headers: {
        'Accept': '*/*',
        'Authorization': 'Bearer ${await getToken()}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> books = json.decode(response.body);

      return books.length;
    } else {
      throw Exception('Falha ao carregar os livros');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserPosts() async {
    final url = Uri.parse('$BASE_URL/api/Post/user-posts');
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Converter a resposta JSON para uma lista de posts
        final List<dynamic> posts = json.decode(response.body);

        // Retornar a lista de posts como um List<Map<String, dynamic>>
        return posts.map((post) => post as Map<String, dynamic>).toList();
      } else {
        throw Exception('Falha ao carregar os posts');
      }
    } catch (e) {
      print('Erro ao carregar os posts: $e');
      throw Exception('Erro ao carregar os posts. Detalhes: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserBooks() async {
    try {
      // Obtendo o token do SharedPreferences
      String? token = await getToken();

      // Verificando se o token é nulo
      if (token == null) {
        throw Exception('Token não encontrado');
      }

      // Definindo a URL da requisição
      final url = Uri.parse('$BASE_URL/api/WriterBooks/list-approved');

      // Realizando a requisição HTTP GET
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Verificando o código de status da resposta
      if (response.statusCode == 200) {
        // Se a resposta for bem-sucedida, processamos os dados
        List<dynamic> responseData = json.decode(response.body);

        // Mapeando os dados dos livros
        return responseData.map((bookData) {
          return {
            'title': bookData['title'],
            'author': bookData['author'],
            'coverUrl':
                '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=${bookData['VolumeId']}',
          };
        }).toList();
      } else {
        // Tratamento para erro 404 ou outros códigos de erro
        String errorMessage = 'Erro ao carregar livros: ${response.statusCode}';
        if (response.statusCode == 401) {
          errorMessage = 'Erro de autenticação: Token inválido ou expirado.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Recurso não encontrado.';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Captura de qualquer exceção e log da mensagem de erro
      if (e is http.ClientException) {
        // Captura de erros específicos do cliente HTTP
        throw Exception(
            'Erro ao buscar livros: Falha na requisição: ${e.message}');
      } else if (e is FormatException) {
        // Captura de erros ao tentar decodificar a resposta (JSON)
        throw Exception('Erro ao decodificar a resposta JSON: $e');
      } else {
        // Outros erros
        throw Exception('Erro desconhecido ao buscar livros: $e');
      }
    }
  }

  static Future<List<WriterBook>> fetchApprovedBooks() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/WriterBooks/list-approved'),
      headers: {
        'Authorization': 'Bearer ${await getToken()}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((book) => WriterBook.fromJson(book)).toList();
    } else {
      throw Exception("Failed to load books");
    }
  }

  static Future<List<WriterBook>> fetchPendingBooks() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/WriterBooks/list-pendingBooks'),
      headers: {
        'Authorization': 'Bearer ${await getToken()}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((book) => WriterBook.fromJson(book)).toList();
    } else {
      throw Exception("Failed to load books");
    }
  }

  static Future<bool> addBookByISBN(String isbn) async {
    final url = Uri.parse('$BASE_URL/api/WriterBooks/add');
    final headers = await AuthProvider.getHeaders();
    final body = json.encode({'isbn': isbn, 'price': 2});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Livro adicionado com sucesso!');
        return true;
      } else {
        print(
            'Erro ao adicionar o livro: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Erro ao adicionar o livro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao adicionar o livro: $e');
      throw Exception('Erro ao adicionar o livro. Detalhes: $e');
    }
    return false;
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }
}
