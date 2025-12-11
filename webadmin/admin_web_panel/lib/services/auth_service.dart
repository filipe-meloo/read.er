import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AuthService {
  /// Faz login do usuário e armazena o token
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$BASE_URL/api/Auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Armazena o token localmente nas SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', token);

        return true;
      } else {
        throw Exception("Erro ao fazer login: ${response.body}");
      }
    } catch (e) {
      throw Exception("Erro na conexão: $e");
    }
  }

  static Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool success = await prefs.remove('jwtToken');
      await prefs.clear();
      print("Token removido: $success"); // Log para depuração
    } catch (e) {
      print("Erro ao fazer logout: $e");
    }
  }

  /// Verifica se o usuário está logado, ou seja, se o token existe
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken') != null;
  }

  /// Recupera o token armazenado
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  /// Recupera o role do usuário a partir do token JWT
  static Future<String?> getUserRole() async {
    String? token = await getToken();

    if (token != null) {
      final url = Uri.parse('$BASE_URL/api/Auth/myRole');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      try {
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          if (data.containsKey('role')) {
            return data['role'];
          } else {
            throw Exception('O campo "role" não foi encontrado na resposta.');
          }
        } else {
          throw Exception(
              'Falha ao obter o role do utilizador. Status Code: ${response.statusCode}.');
        }
      } catch (e) {
        throw Exception("Erro na conexão: $e");
      }
    }

    throw Exception('Token JWT não encontrado.');
  }
}
