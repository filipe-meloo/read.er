import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/config.dart';
import 'notification_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$BASE_URL/api/Auth/login');
    final NotificationService notificationService = NotificationService();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwtToken', token);

      await notificationService.connectWebSocket();

      return true;
    } else {
      throw Exception("Erro ao fazer login: ${response.body}");
    }
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final NotificationService notificationService = NotificationService();
    await prefs.clear();
    await prefs.remove('jwtToken'); 
    notificationService.disconnectWebSocket;
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken') != null;
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  static Future<String?> getUserRole() async {
    String? token = await getToken();

    if (token != null) {
      final url = Uri.parse('$BASE_URL/api/Auth/myRole'); // Endpoint para obter o role

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
