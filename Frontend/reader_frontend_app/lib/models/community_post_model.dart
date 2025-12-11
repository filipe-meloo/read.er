class CommunityPostModel {
  final int id;
  final String content;
  final DateTime createdAt;
  final String type;
  final String username; // Nome do autor do post
  final int numberOfReactions;
   int numberOfComments;
  final int numberOfReposts;
  final String communityName; // Adiciona o campo `communityName`


  CommunityPostModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.username,
    required this.numberOfReactions,
    required this.numberOfComments,
    required this.numberOfReposts,
    required this.communityName // Inicialização do campo

  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['iD_Post'],
      content: json['conteudo'],
      createdAt: DateTime.parse(json['data_Criacao']),
      communityName: json['communityName'],
      type: json['tipo'],
      username: json['username'], // Mapeia o campo `username`
      numberOfReactions: json['numberOfReactions'] ?? 0,
      numberOfComments: json['numberOfComments'] ?? 0,
      numberOfReposts: json['numberOfReposts'] ?? 0,
    );
  }
}
