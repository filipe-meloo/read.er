class SaleTradeReview {
  final int id;
  final int sellerId;
  final int reviewerId;
  final int tradeOfferId;
  final int rating;
  final String comment;

  SaleTradeReview({
    required this.id,
    required this.sellerId,
    required this.reviewerId,
    required this.tradeOfferId,
    required this.rating,
    required this.comment,
  });
  factory SaleTradeReview.fromJson(Map<String, dynamic> json) {
    return SaleTradeReview(
      id: json['id'],
      sellerId: json['sellerId'],
      reviewerId: json['reviewerId'],
      tradeOfferId: json['tradeOfferId'],
      rating: json['rating'],
      comment: json['comment'],
    );
  }
}
