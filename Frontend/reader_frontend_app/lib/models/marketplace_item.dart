import 'sale_trade.dart';

class MarketplaceItem {
  final int id;
  final String title;
  final String author; // Replace with real author if available
  final double price;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'],
      title: json['title'],
      author: json['author'] ?? "Unknown Author",
      price: (json['price'] as num).toDouble(),
    );
  }

  // Create from SaleTrade
  factory MarketplaceItem.fromSaleTrade(SaleTrade saleTrade) {
    return MarketplaceItem(
      id: saleTrade.id,
      title: saleTrade.notes ?? "No Title",
      author: "Unknown Author", // Add logic to fetch author if available
      price: saleTrade.price ?? 0.0,
    );
  }
}
