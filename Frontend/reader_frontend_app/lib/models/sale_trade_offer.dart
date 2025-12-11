class SaleTradeOffer {
  final int idOffer;
  final int idUser;
  final String isbnOfferedBook;
  final String offeredBookTitle; // Adicionado
  final String? message;
  final DateTime dateOffered;
  final bool declined;
  final String status;
  final int idSaleTrade; // Pode ser nulo, mas deve ter um valor padrão
  final String saleTradeTitle;
  final String? saleTradeIsbn;
  final int saleTradeOwnerId; // Pode ser nulo, mas deve ter um valor padrão

  SaleTradeOffer({
    required this.idOffer,
    required this.idUser,
    required this.isbnOfferedBook,
    required this.offeredBookTitle, // Novo campo
    this.message,
    required this.status,
    required this.dateOffered,
    required this.declined,
    required this.idSaleTrade,
    required this.saleTradeTitle,
    this.saleTradeIsbn,
    required this.saleTradeOwnerId,
  });

  factory SaleTradeOffer.fromJson(Map<String, dynamic> json) {
    return SaleTradeOffer(
      idOffer: json['idOffer'],
      idUser: json['idUser'] ?? -1, // Valor padrão se for null
      isbnOfferedBook: json['isbnOfferedBook'] ?? 'Unknown ISBN',
      offeredBookTitle: json['offeredBookTitle'] ?? 'Unknown Title',
      message: json['message'],
      dateOffered: DateTime.parse(json['dateOffered']),
      declined: json['declined'],
      status: json['status'] ?? 'Unknown',
      idSaleTrade: json['idSaleTrade'] ?? -1, // Valor padrão para campos nulos
      saleTradeTitle: json['saleTradeTitle'] ?? 'Unknown Title',
      saleTradeIsbn: json['saleTradeIsbn'],
      saleTradeOwnerId: json['saleTradeOwnerId'] ?? -1, // Valor padrão para campos nulos
    );
  }
}
