import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendshipService {
  static Future<List<Map<String, dynamic>>> fetchFriendRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    final response = await http.get(
      Uri.parse('$BASE_URL/api/UserFriendship/GetFriendRequests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data.map((item) => {
          'id': item['requesterId'],
          'name': item['requesterName'],
          'username': item['requesterUsername'],
        }));
      } else {
        throw Exception("Formato inesperado de dados: $data");
      }
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception("Erro ao buscar solicitações de amizade");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFriends() async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/GetFriends');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(json.decode(response.body));
      print(data); // Debug: Verifique o conteúdo retornado
      return data.map((friend) {
        return {
          'FriendId': friend['friendId'] ?? 0,
          'FriendName': friend['friendName'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Erro ao buscar amigos: ${response.reasonPhrase}');
    }
  }


  static Future<void> removeFriend(int friendId) async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/RemoveFriend/$friendId');
    final headers = await AuthProvider.getHeaders();

    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao remover amizade: ${response.reasonPhrase}');
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query, Map<String, String> headers) async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/SearchUsers/$query');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      return users.map((user) {
        return {
          'id': user['id'],
          'username': user['username'],
          'name': user['nome'],
        };
      }).toList();
    } else if (response.statusCode == 404) {
      return []; // Retorna uma lista vazia se nenhum usuário for encontrado
    } else {
      throw Exception('Erro ao buscar usuários: ${response.reasonPhrase}');
    }
  }


  static Future<void> sendFriendRequest(int userId) async {
    final url = Uri.parse('$BASE_URL/api/UserFriendship/SendFriendRequest/$userId');
    final headers = await AuthProvider.getHeaders();

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar solicitação de amizade: ${response.reasonPhrase}');
    }
  }

  static Future<void> acceptFriendRequest(int requesterId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    await http.post(
      Uri.parse(
          '$BASE_URL/api/UserFriendship/AcceptFriendRequest/$requesterId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }






  static Future<void> declineFriendRequest(int requesterId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    await http.post(
      Uri.parse(
          '$BASE_URL/api/UserFriendship/DeclineFriendRequest/$requesterId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
