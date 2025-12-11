import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/sale_trade.dart';
import '../../services/marketplace_service.dart';
import 'trade_proposal_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/wishlist_item.dart';

class MarketSection extends StatelessWidget {
  final List<SaleTrade> marketItems;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final Function reloadData;

  MarketSection({super.key, required this.marketItems, required this.reloadData});

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  WishlistItem convertSaleTradeToWishlistItem(SaleTrade saleTrade) {
    return WishlistItem(
      saleTradeId: saleTrade.id,
      isbn: saleTrade.isbn,
      saleTradeTitle: saleTrade.title,
      idUser: saleTrade.idUser,
      author: null,
      saleTradePrice: saleTrade.price,
      sellerName: saleTrade.username,
      saleTradeState: saleTrade.state,
      description: saleTrade.notes,
      dateAdded: DateTime.now(),
      desiredBookISBN: saleTrade.isbnDesiredBook,
      isAvailableForTrade: saleTrade.isAvailableForTrade,
    );
  }

  void _addToWishlist(SaleTrade item, BuildContext context, Function reloadData) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception("User não autenticado!");

      await _marketplaceService.addToWishlist(token, item.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Adicionado à wishlist com sucesso!")),
      );

      reloadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao adicionar à wishlist: $e")),
      );
    }
  }

  void _payForItem(int saleTradeId, BuildContext context) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception("User não autenticado!");

      final session = await _marketplaceService.createCheckoutSession(token, saleTradeId);

      final checkoutUrl = session["checkoutUrl"];
      print("Checkout URL: $checkoutUrl");

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("URL inválido ou impossibilidade de abrir o link.");
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao iniciar pagamento: $e")),
      );
    }
  }

  void _proposeTrade(SaleTrade item, BuildContext context) {
    final wishlistItem = convertSaleTradeToWishlistItem(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TradeProposalModal(
        saleTradeItem: wishlistItem,
        onTradeProposalSubmit: (isbnOffered, message) async {
          String? token = await _getToken();
          if (token != null) {
            try {
              await _marketplaceService.sendTradeProposal(
                token,
                item.id,
                isbnOffered,
                message,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Proposta de troca enviada com sucesso!")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erro ao enviar proposta de troca: $e")),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Market",
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.05, // Fonte proporcional à largura da tela
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        _buildGrid(context),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth ~/ 200).clamp(2, 4); // Ajusta dinamicamente as colunas

    final availableItems = marketItems.where((item) {
      return item.isAvailableForSale || item.isAvailableForTrade;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Ajusta a proporção entre largura e altura
      ),
      itemCount: availableItems.length,
      itemBuilder: (context, index) {
        final item = availableItems[index];
        return _buildMarketItem(item, context);
      },
    );
  }
  Widget _buildMarketItem(SaleTrade item, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2C1A3D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white, size: 12),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.username ?? "Unknown",
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite_border, color: Colors.red, size: 16),
                onPressed: () {
                  _addToWishlist(item, context, reloadData);
                },
              ),
            ],
          ),
          SizedBox(height: 6),
          Icon(Icons.book, size: screenWidth * 0.08, color: Colors.white),
          SizedBox(height: 6),
          Text(
            item.title ?? "No Title",
            style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            item.price != null ? "${item.price!.toStringAsFixed(2)}€" : "N/A",
            style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.03),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (item.isAvailableForSale)
                GestureDetector(
                  onTap: () => _payForItem(item.id, context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "PAY",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (item.isAvailableForTrade)
                GestureDetector(
                  onTap: () => _proposeTrade(item, context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "TRADE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}