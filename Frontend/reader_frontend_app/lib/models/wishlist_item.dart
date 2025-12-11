
class WishlistItem {
  final int saleTradeId;
  final String? isbn;
  final String? saleTradeTitle;
  String? saleTradeDesiredBookTitle;
  final int idUser;
  final String? author;
  final double? saleTradePrice;
  final String? sellerName;
  final String? saleTradeState;
  final String? description;
  final DateTime dateAdded;
  final String? desiredBookISBN;
  bool? isAvailableForTrade;


  WishlistItem({
    required this.saleTradeId,
    this.isbn,
    this.saleTradeTitle,
    required this.idUser,
    this.author,
    this.saleTradePrice,
    this.sellerName,
    this.saleTradeState,
    this.description,
    required this.dateAdded,
    this.desiredBookISBN,
    this.saleTradeDesiredBookTitle,
    this.isAvailableForTrade,

  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      saleTradeId: json['saleTradeId'],
      isbn: json['isbn'],
      saleTradeTitle: json['title'],
      saleTradeDesiredBookTitle: json['desiredBookTitle'],
      idUser: json['idUser'],
      author: json['author'],
      saleTradePrice: json['price'] != null ? (json['price'] as num).toDouble() : null,
      sellerName: json['sellerName'],
      saleTradeState: json['state'],
      description: json['description'],
      dateAdded: DateTime.parse(json['dateAdded']),
      desiredBookISBN: json['desiredBookISBN'],
      isAvailableForTrade: json['isAvailableForTrade'],

    );
  }
}
