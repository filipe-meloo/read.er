import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'config.dart';

class AdminService {
  // Fetch metrics
  static Future<Map<String, dynamic>> fetchMetrics(List<String> metrics) async {
    final token = await AuthService.getToken();
    final url = Uri.parse(
        "$BASE_URL/api/admin/metrics?metrics=${metrics.join('&metrics=')}");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao obter métricas: ${response.body}");
    }
  }

// Atualize o método fetchUsers no AdminService:
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/users");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = List<Map<String, dynamic>>.from(json.decode(response.body));
      return data.map((user) {
        return {
          "id": user["id"] ?? 0, 
          "nome": user["nome"] ?? "Desconhecido",
          "email": user["email"] ?? "Sem email",
          "isActive": user["isActive"] ?? false,
        };
      }).toList();
    } else {
      throw Exception("Erro ao listar utilizadores: ${response.body}");
    }
  }

  // Toggle user status
  static Future<void> toggleUserStatus(int userId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/users/$userId/toggle-status");

    final response = await http.patch(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception(
          "Erro ao atualizar estado do utilizador: ${response.body}");
    }
  }

  // Fetch reported posts
  static Future<List<dynamic>> fetchReportedPosts() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/posts/reported");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao obter posts reportados: ${response.body}");
    }
  }

  // Mark post as inappropriate
  static Future<void> markPostAsInappropriate(int postId) async {
    final token = await AuthService.getToken();
    final url =
        Uri.parse("$BASE_URL/api/admin/posts/$postId/mark-inappropriate");

    final response = await http.patch(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao marcar post como impróprio: ${response.body}");
    }
  }

  // Delete post
  static Future<void> deletePost(int postId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/posts/$postId");

    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao excluir o post: ${response.body}");
    }
  }

  // Fetch transactions
  static Future<List<dynamic>> fetchTransactions() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/completed-sales");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao obter transações: ${response.body}");
    }
  }

  // Delete transaction
  static Future<void> deleteTransaction(int transactionId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/completed-sales/$transactionId");

    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao excluir a transação: ${response.body}");
    }
  }

  // Resolve report
  static Future<void> resolveReport(int postId, {required bool remove}) async {
    final token = await AuthService.getToken();
    final url =
        Uri.parse("$BASE_URL/api/admin/$postId/decision-report?remove=$remove");

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao resolver o report: ${response.body}");
    }
  }

  // Block community
  static Future<void> blockCommunity(int communityId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/community/$communityId/block");

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao bloquear a comunidade: ${response.body}");
    }
  }

  // Unblock community
  static Future<void> unblockCommunity(int communityId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/community/$communityId/unblock");

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao desbloquear a comunidade: ${response.body}");
    }
  }

  // Fetch communities
  static Future<List<dynamic>> fetchCommunities() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/admin/communities");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erro ao buscar comunidades: ${response.body}");
    }
  }

  // Fetch books for approval
  static Future<List<dynamic>> fetchBooksForApproval() async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/WriterBooks/list-pendingBooks");

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          "Erro ao buscar livros pendentes de aprovação: ${response.body}");
    }
  }

  // Approve book
  static Future<void> approveBook(int bookId) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/BookApproval/approve/$bookId");

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception("Erro ao aprovar livro: ${response.body}");
    }
  }

  // Reject book
  static Future<void> rejectBook({
    required int bookId,
    required String reason,
  }) async {
    final token = await AuthService.getToken();
    final url = Uri.parse("$BASE_URL/api/BookApproval/reject/$bookId");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({"reason": reason}),
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao rejeitar livro: ${response.body}");
    }
  }
}
