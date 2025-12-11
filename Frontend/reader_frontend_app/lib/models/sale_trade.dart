class SaleTrade {
  final int id;
  final int idUser;
  final String isbn;
  final String title;
  final String? desiredBookTitle;
  final String username; // Novo campo para o nome do vendedor
  final double? price;
  final bool isAvailableForSale;
  final bool isAvailableForTrade;
  final String state;
  final String? notes;
  final String? isbnDesiredBook;
  final DateTime dateCreation;

  SaleTrade({
    required this.id,
    required this.idUser,
    required this.isbn,
    required this.title,
    this.price,
    this.desiredBookTitle,
    required this.isAvailableForSale,
    required this.isAvailableForTrade,
    required this.state,
    this.notes,
    this.isbnDesiredBook,
    required this.username,
    required this.dateCreation,
  });

  factory SaleTrade.fromJson(Map<String, dynamic> json) {
    return SaleTrade(
      id: json['id'] ?? (throw Exception('Campo `id` é nulo')),
      idUser: json['idUser'] ?? (throw Exception('Campo `idUser` é nulo')),
      isbn: json['isbn'] ?? 'ISBN não disponível',
      title: json['title'] ?? 'Título não disponível',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      desiredBookTitle:
      json['desiredBookTitle'] ?? 'Título do livro desejado não disponível',
      isAvailableForSale: json['isAvailableForSale'] ?? false,
      isAvailableForTrade: json['isAvailableForTrade'] ?? false,
      state: json['state'] ?? 'Indefinido',
      username: json['username'] ?? 'Nome do vendedor não disponível',
      notes: json['notes'],
      isbnDesiredBook: json['isbnDesiredBook'],
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : DateTime.now(),
    );
  }
}
