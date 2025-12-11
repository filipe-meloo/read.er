import '/enumeracoes/status.dart';


class LibraryBook {
  final String isbn;
  final String volumeId;
  final String coverUrl;
  final String title;
  final String author;
  int pagesRead;
  final int totalPages; // Certifica-te de que este campo corresponde ao "length" no JSON
  double progressPercentage;
  final String description;
  Status status;

  LibraryBook({
    required this.isbn,
    required this.volumeId,
    required this.coverUrl,
    required this.title,
    required this.author,
    required this.pagesRead,
    required this.totalPages,
    required this.progressPercentage,
    required this.description,
    required this.status
  });

  // Método para converter JSON em um objeto LibraryBook
  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      isbn: json['isbn'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      volumeId: json['volumeId'] ?? '',
      status: _mapStringToStatus(json['status'] ?? 'TBR'),
      coverUrl: json['coverUrl'] ?? '',
      pagesRead: json['pagesRead'] ?? 0,
      totalPages: json['length'] ?? 0,
      progressPercentage: json['percentageRead']?.toDouble() ?? 0.0,
      description: json['description'] ?? 'Descrição não disponível',
    );
  }

  static Status _mapStringToStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT_READ':
        return Status.CURRENT_READ;
      case 'READ':
        return Status.READ;
      case 'TBR':
      default:
        return Status.TBR;
    }
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LibraryBook &&
              runtimeType == other.runtimeType &&
              isbn == other.isbn; // Comparar pelo ISBN

  @override
  int get hashCode => isbn.hashCode;

  get id => null; // Usar o ISBN como identificador único

}
