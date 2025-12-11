import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import '../models/community_post_model.dart';
import '/models/community_model.dart';
import 'config.dart';
import 'auth_service.dart';

class CommunityService {
  static const String baseUrl = '$BASE_URL/api/Community';

  Future<void> joinCommunity(int communityId, String role) async {
    try {
      final headers = await AuthProvider.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/JoinRequest/$communityId/$role'),
        headers: headers,
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao enviar pedido de adesão: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao juntar-se à comunidade: $e');
    }
  }

  Future<void> rejectRequest(int communityId, int userId) async {
    final url = Uri.parse('$baseUrl/RejectJoinRequest/$communityId/$userId');
    final response = await http.delete(url, headers: await AuthProvider.getHeaders());

    if (response.statusCode != 200) {
      throw Exception("Erro ao rejeitar o pedido: ${response.body}");
    }
  }


  Future<void> createCommunity(String name, String description) async {
    try {
      final headers = await AuthProvider.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/CreateCommunity'),
        headers: headers,
        body: json.encode({
          'communityName': name,
          'communityDescritpion': description,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['Message'] ?? 'Erro ao criar comunidade.');
      }
    } catch (e) {
      throw Exception("Erro ao criar comunidade: $e");
    }
  }

  Future<void> createTopic(int communityId, String topicName) async {
    final url = Uri.parse('$baseUrl/CreateTopic?communityId=$communityId');
    final headers = await AuthProvider.getHeaders();
    headers['Content-Type'] = 'application/json'; // Certifique-se de definir o Content-Type

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(topicName), // Codifica o nome do tópico como JSON
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao criar tópico: ${response.body}");
    }
  }
  Future<void> toggleTopicStatus(int communityId, int topicId) async {
    final url = Uri.parse('$baseUrl/ToggleTopicStatus/$communityId/$topicId');

    try {
      final headers = await AuthProvider.getHeaders();
      final response = await http.post(url, headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Erro ao alternar o status do tópico: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao alternar o status do tópico: $e');
    }
  }
  Future<List<dynamic>> fetchCommunityTopics(int communityId) async {
    final url = Uri.parse('$baseUrl/GetCommunityTopics/$communityId');

    try {
      final headers = await AuthProvider.getHeaders(); // Obtém os headers para autenticação
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar tópicos da comunidade: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar tópicos da comunidade: $e');
    }
  }



  Future<void> approveRequest(int communityId, int userId) async {
    final url = Uri.parse('$baseUrl/AcceptJoinRequest/$communityId/$userId');

    try {
      // Obter os headers para autenticação
      final headers = await AuthProvider.getHeaders();

      // Chamar o endpoint POST
      final response = await http.post(url, headers: headers);

      // Verificar o status da resposta
      if (response.statusCode != 200) {
        throw Exception("Erro ao aprovar o pedido: ${response.body}");
      }
    } catch (e) {
      throw Exception("Erro ao aprovar o pedido: $e");
    }
  }

  Future<List<dynamic>> fetchPendingRequests(int communityId) async {
    final url = Uri.parse('$baseUrl/GetRequests/$communityId');

    try {
      // Obter os headers para autenticação
      final headers = await AuthProvider.getHeaders();

      // Fazer a requisição GET com os headers
      final response = await http.get(url, headers: headers);

      // Verificar o status da resposta
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Erro ao buscar pedidos pendentes: ${response.body}");
      }
    } catch (e) {
      throw Exception("Erro ao buscar pedidos pendentes: $e");
    }
  }


  // Função para fazer upload de imagem da comunidade
  Future<String> uploadCommunityImage(int communityId, File image) async {
    try {
      final headers = await AuthProvider.getHeaders();
      final uri = Uri.parse('$baseUrl/UploadCommunityPhoto/$communityId');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        return decodedResponse['profilePictureUrl'] ?? "";
      } else {
        throw Exception('Erro ao fazer upload da imagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao enviar imagem: $e');
    }
  }



  static Future<List<CommunityModel>> fetchUserCommunities() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token inválido ou não encontrado.");
    }

    final url = Uri.parse('$baseUrl/GetUserCommunities');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = json.decode(response.body);
        print("Parsed data: $data");
        return data.map((json) => CommunityModel.fromJson(json)).toList();
      } catch (e) {
        print("Erro ao parsear a resposta: $e");
        throw Exception("Erro no formato da resposta do servidor.");
      }
    } else {
      throw Exception("Erro ao carregar comunidades: ${response.reasonPhrase}");
    }
  }



  Future<void> removeMember(int communityId, int memberNumber) async {
    final url = Uri.parse('$baseUrl/RemoveMember/$communityId/$memberNumber');
    final headers = await AuthProvider.getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erro ao remover membro: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchCommunityMembers(int communityId) async {
    final url = Uri.parse('$baseUrl/ListCommunityMembers/$communityId');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar membros: ${response.body}');
    }
  }

  static Future<bool> checkIfUserIsMember(int communityId) async {
    final url = Uri.parse('$baseUrl/IsUserMember/$communityId');

    // Obtém os cabeçalhos com o token de autenticação
    final headers = await AuthProvider.getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isMember'];  // Retorna se o usuário é membro
      } else {
        throw Exception("Erro ao verificar a adesão do usuário.");
      }
    } catch (e) {
      throw Exception("Erro ao verificar a adesão do usuário: $e");
    }
  }




  static Future<Map<String, dynamic>> fetchCommunityDetails(int communityId) async {
    try {
      final headers = await AuthProvider.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/GetCommunityDetails/$communityId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Erro ao carregar os detalhes da comunidade: ${response.body}");
      }
    } catch (e) {
      throw Exception("Erro na requisição: $e");
    }
  }
  static Future<void> leaveCommunity(int communityId) async {
    final url = Uri.parse('$baseUrl/LeaveCommunity/$communityId');

    // Obtém os cabeçalhos do serviço
    final headers = await AuthProvider.getHeaders();

    final response = await http.delete(
      url,
      headers: headers, // Inclui os cabeçalhos com o token
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao sair da comunidade.');
    }
  }

  Future<List<dynamic>> fetchUserOwnedCommunities() async {
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/GetUserOwnedCommunities'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao carregar comunidades do usuário.');
    }
  }

  static Future<List<CommunityPostModel>> fetchCommunityPosts(int communityId) async {
    if (communityId <= 0) {
      throw Exception("ID da comunidade inválido.");
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Token inválido ou não encontrado.");
    }

    final url = Uri.parse('$baseUrl/GetCommunityPosts/$communityId');
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Mapear os dados para o modelo `CommunityPostModel`
        return data.map((json) => CommunityPostModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception("Comunidade não encontrada.");
      } else {
        throw Exception("Erro ao carregar posts: ${response.reasonPhrase}");
      }
    } catch (error) {
      // Adicionar tratamento de erros para conexão ou decodificação
      print("Erro na fetchCommunityPosts: $error");
      throw Exception("Erro inesperado ao carregar posts.");
    }
}

}
