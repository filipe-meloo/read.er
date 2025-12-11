import '../services/auth_service.dart';

class AuthMiddleware {
  // Método para verificar se o utilizador é administrador
  static Future<bool> isAdmin() async {
    try {
      final role = await AuthService.getUserRole();

      return role?.toLowerCase() ==
          'admin'; 
    } catch (e) {
      print("Erro na verificação de admin: $e");
      return false;
    }
  }
}
