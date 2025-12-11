import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reader_frontend_app/services/auth_provider.dart';
import '../models/community_post_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'auth_service.dart';
import 'config.dart';

class PostService {
  static const String baseUrl = '$BASE_URL/api/Post';
    static const String baseUrl2 = '$BASE_URL/api/Community';

  static Future<List<PostModel>> fetchPostsForUser(int userId) async {
    final url = Uri.parse('$baseUrl/user-posts/$userId');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((post) => PostModel.fromJson(post)).toList();
    } else {
      throw Exception('Erro ao buscar posts do usuário: ${response.reasonPhrase}');
    }
  }

  static Future<void> createPost({
    required String content,
    required String tipoPublicacao,
    String? tituloLivro,
    int? communityId, // Adicionado para permitir posts em comunidades
    int? topicId,     // Opcional: Suporte a tópicos específicos
  }) async {
    final url = Uri.parse('$baseUrl/create');
    final headers = await AuthProvider.getHeaders();
    final body = json.encode({
      "Conteudo": content,
      "TipoPublicacao": tipoPublicacao,
      "TituloLivro": tituloLivro,
      "IdCommunity": communityId, // Parâmetro opcional para comunidade
      "TopicId": topicId,         // Parâmetro opcional para tópico
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Erro ao criar post: ${response.reasonPhrase}');
    }
  }

  static Future<List<PostModel>> fetchUserPosts() async {
    final url = Uri.parse('$baseUrl/user-posts'); // Substitua '/user/posts' pela rota correta do endpoint
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((item) => PostModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao buscar posts do utilizador: ${response.reasonPhrase}');
    }
  }

  static Future<void> createCommunityPost({
    required String content,
    required String tipoPublicacao,
    required int communityId,
    int? topicId, // Campo opcional para o ID do tópico
    String? tituloLivro,
  }) async {
    final url = Uri.parse('$baseUrl/create');
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("Token inválido ou não encontrado.");
    }

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    final body = json.encode({
      "Conteudo": content,
      "TipoPublicacao": tipoPublicacao,
      "IdCommunity": communityId,
      "TopicId": topicId, // Inclui o topicId na requisição
      "TituloLivro": tituloLivro,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception('Erro ao criar post na comunidade: $errorBody');
    }
  }



  static Future<List<PostModel>> fetchPosts() async {
    final url = Uri.parse('$baseUrl/list');
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((item) => PostModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao buscar posts: ${response.reasonPhrase}');
    }
  }

  static Future<void> reactToPost(int postId, String reactionType) async {
    final url = Uri.parse('$baseUrl/ReactToPost?postId=$postId&reactionType=$reactionType');
    final headers = await AuthProvider.getHeaders();

    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erro ao reagir ao post.');
    }
  }


  static Future<List<CommunityPostModel>> fetchCommunityPosts(int communityId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception("Token inválido ou não encontrado.");
    }

    final url = Uri.parse('$baseUrl2/GetCommunityPosts/$communityId');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CommunityPostModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return []; // Comunidade sem posts
    } else {
      throw Exception('Erro ao buscar posts: ${response.reasonPhrase}');
    }
  }

  static Future<void> commentOnPost(int postId, String content) async {
    try {
      final url = Uri.parse('$baseUrl/CommentOnPost?postId=$postId');
      final headers = await AuthProvider.getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'content': content}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao comentar no post. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('Exception occurred: $e');
      print('StackTrace: $stackTrace');
      rethrow; // Relança a exceção para ser tratada no chamador
    }
  }


  static Future<List<CommentModel>> fetchComments(int postId) async {
    final url = Uri.parse('$baseUrl/$postId/comments'); // URL correta com o postId no path
    final headers = await AuthProvider.getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => CommentModel.fromJson(item)).toList();
    } else {
      throw Exception('Erro ao buscar comentários: ${response.reasonPhrase}');
    }
  }



  static Future<void> sharePost(int postId) async {
    final url = Uri.parse('$baseUrl/share?postId=$postId');
    final headers = await AuthProvider.getHeaders();
    final response = await http.post(url, headers: headers);
    if (response.statusCode != 200) {
      throw response;
    }
  }

}