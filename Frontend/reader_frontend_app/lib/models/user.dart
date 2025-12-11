class User {
  final String username;
  final String role;
  final String email;
  final String nome;
  final String dbo;
  final String bio;
  String? profilePictureUrl;

  User({
    required this.username,
    required this.role,
    required this.email,
    required this.nome,
    required this.dbo,
    required this.bio,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'] ?? '',
      dbo: json['dbo'] ?? '',
      bio: json['bio'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
    );
  }

  get id => null;

  get userId => null;
}
