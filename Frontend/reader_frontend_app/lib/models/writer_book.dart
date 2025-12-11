class WriterBook {
  final int id;
  final String title;
  final String Isbn;
  final String author;
  final String coverUrl;
  final String volumeId;
  final bool isPromoted;
  final String description;

  WriterBook({
    required this.id,
    required this.Isbn,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.volumeId,
    required this.isPromoted,
    required this.description,
  });

  factory WriterBook.fromJson(Map<String, dynamic> json) {
    return WriterBook(
      id: json['id'],
      Isbn: json['isbn']?? "",
      title: json['title'],
      author: json['author'],
      coverUrl: json['coverUrl'] ?? "",
      volumeId: json['volumeId'] ?? "",
      isPromoted: json['isPromoted'] == true || json['isPromoted'] == 1,
      description: json['description'] ?? "",

    );
  }

}
