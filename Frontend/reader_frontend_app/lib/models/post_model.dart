class PostModel {
  final int id;
  final String username;
  final String content;
  final int? originalPostId; // ID do post original, se for uma republicação
  final String? originalUsername; // Nome do autor do post original
  final String? isbn;
  final int numberOfReactions;
  int numberOfReposts;
  int numberOfComments;
  final String bookTitle;

  PostModel({
    required this.id,
    required this.username,
    required this.content,
    this.originalPostId,
    this.originalUsername,
    this.isbn,
    required this.bookTitle,
    required this.numberOfReactions,
    required this.numberOfComments,
    required this.numberOfReposts,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['postId'],
      username: json['username'],
      content: json['content'],
      originalPostId: json['originalPostId'],
      originalUsername: json['originalUsername'],
      isbn: json['isbn'],
      bookTitle: json['bookTitle'],
      numberOfReactions: json['numberOfReactions'],
      numberOfComments: json['numberOfComments'],
      numberOfReposts: json['numberOfReposts'],
    );
  }

  get repostsCount => null;
}
