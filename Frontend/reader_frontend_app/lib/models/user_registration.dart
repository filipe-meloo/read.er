import '../enumeracoes/role.dart';

class UserRegistration {
  final String username;
  final Role role;
  final String email;
  final String password;
  final String nome;
  final DateTime nascimento;
  final bool isActive;
  final String bio;

  UserRegistration({
    required this.username,
    required this.role,
    required this.email,
    required this.password,
    required this.nome,
    required this.nascimento,
    required this.isActive,
    required this.bio,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'email': email,
      'password': password,
      'nome': nome,
      'nascimento': nascimento.toIso8601String(),  
      'bio': bio,  
      'isActive': isActive,
    };
  }
}
