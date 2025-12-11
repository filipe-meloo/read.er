import 'dart:convert';

import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/models/user.dart';

class UserProfileService {

  // Defina a URL base para o serviço de perfil de usuário
  static const String baseUrl = '$BASE_URL/api/UserProfile';
  static const String baseUrl2 = '$BASE_URL/api/PersonalLibrary';

  // Método para atualizar o perfil do usuário
  static Future<String> updateUserProfile({
    required int userId,
    required String username,
    required String nome,
    required String email,
    required String nascimento,
    required String bio,
  }) async {
    // Passando o id como parâmetro de query
    final url = Uri.parse('$baseUrl/?id=$userId');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwtToken');
    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      'username': username,
      'nome': nome,
      'email': email,
      'nascimento': nascimento,
      'bio': bio,
    };

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['message'] ?? 'Perfil atualizado com sucesso!';
      } else {
        throw Exception(
            'Erro ao atualizar o perfil: ${response.statusCode} - ${response
                .body}');
      }
    } catch (error) {
      throw Exception('Erro ao atualizar o perfil: $error');
    }
  }
  static Future<Map<String, dynamic>> fetchOtherUserProfile(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwtToken');

    if (token == null) {
      throw Exception("Token não encontrado.");
    }

    final url = Uri.parse('$baseUrl/OtherUserProfile/$userId');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao buscar perfil do usuário: ${response.reasonPhrase}');
    }
  }
  static Future<int> fetchFriendsCount() async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/GetFriends');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> friends = json.decode(response.body);
      return friends.length; // Retorna o número de amigos
    } else {
      throw Exception('Erro ao buscar amigos: ${response.reasonPhrase}');
    }
  }

  static Future<int> fetchBooksReadedCount() async {
    final url = Uri.parse('$baseUrl2/list-user-readed-books');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> books = json.decode(response.body);
      return books.length;
    } else if (response.statusCode == 404) {
      return 0;
    } else {
      throw Exception('Erro ao buscar livros lidos: ${response.reasonPhrase}');
    }
  }


  // Método para buscar o perfil do usuário
  static Future<User> fetchUserProfile() async {
    final url = Uri.parse('$baseUrl/profile'); // URL correta
    final headers = await AuthProvider.getHeaders();

    try {
      // Envia a requisição GET para buscar os dados do perfil
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido ou expirado. Faça login novamente.');
      } else {
        throw Exception(
            'Erro ao buscar perfil do usuário: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erro ao buscar perfil do usuário: $e');
      throw Exception('Erro ao buscar perfil do usuário.');
    }
  }
}
