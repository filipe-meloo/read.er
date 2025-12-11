class CommunityModel {
  final int id;
  final String name;
  final String? description;
  final int adminId;// Aceitar descrição como opcional

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    required this.adminId,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? 0, // Use um valor padrão caso id seja null
      name: json['name'] ?? "Unknown", // Nome padrão se for null
      description: json['description'],
      adminId: json['adminId']// Permite null
    );
  }
}
