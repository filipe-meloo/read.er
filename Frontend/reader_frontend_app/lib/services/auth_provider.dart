import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  get user => null;

  int? get userId => null;

  void login(BuildContext context) {
    _isLoggedIn = true;
    notifyListeners();
    Navigator.pushNamed(context, '/');
  }

  static Future<Map<String, String>> getHeaders() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwtToken');
      if (token == null) {
        print('Token não encontrado!');
        throw Exception('Token de autenticação não encontrado.');
      }
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }

  void logout(BuildContext context) {
    _isLoggedIn = false;
    notifyListeners();
    Navigator.pushNamed(context, '/login');
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  Future<int> getCurrentUserId() async {
    String? token = await getToken();

    if (token != null) {
      // Converter BASE_URL para Uri e concatenar o caminho
      final url = Uri.parse('$BASE_URL/api/Auth/me');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('userId')) {
          // Converter "userId" para inteiro se necessário.
          return int.parse(data['userId'].toString());
        } else {
          throw Exception('A resposta não contém o campo "userId".');
        }
      } else {
        throw Exception(
            'Falha ao obter o ID do utilizador. Status Code: ${response.statusCode}. Body: ${response.body}');
      }
    }

    throw Exception('Token is null');
  }

  Future<String?> getUserRole() async {
    String? token = await getToken();

    if (token != null) {
      final url =
      Uri.parse('$BASE_URL/api/Auth/myRole'); // Endpoint para obter o role

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

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
    }

    throw Exception('Token JWT não encontrado.');
  }
}
