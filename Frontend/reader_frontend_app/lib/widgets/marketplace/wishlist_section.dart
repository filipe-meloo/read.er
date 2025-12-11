import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/wishlist_item.dart';
import '../../services/marketplace_service.dart';
import 'trade_proposal_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class WishlistSection extends StatefulWidget {
  final List<WishlistItem> wishlistItems;
  final VoidCallback onWishlistUpdated;

  const WishlistSection({
    super.key,
    required this.wishlistItems,
    required this.onWishlistUpdated,
  });

  @override
  _WishlistSectionState createState() => _WishlistSectionState();
}

class _WishlistSectionState extends State<WishlistSection> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  void _removeFromWishlist(WishlistItem item, BuildContext context) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception("Usuário não autenticado!");

      await _marketplaceService.removeFromWishlist(token, item.saleTradeId);

      setState(() {
        widget.wishlistItems.remove(item);
      });

      widget.onWishlistUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Removido da wishlist com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao remover da wishlist: $e")),
      );
    }
  }

  void _payForItem(int saleTradeId, BuildContext context) async {
    try {
      String? token = await _getToken();
      if (token == null) throw Exception("User não autenticado!");

      final session = await _marketplaceService.createCheckoutSession(token, saleTradeId);

      final checkoutUrl = session["checkoutUrl"];
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxisCount = screenWidth > 600 ? 3 : 2; // Ajustar número de colunas baseado no tamanho da tela.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Wishlist",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        _buildGrid(gridCrossAxisCount),
      ],
    );
  }

  Widget _buildGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Controlar a proporção dos cards.
      ),
      itemCount: widget.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = widget.wishlistItems[index];
        return _buildWishlistItem(item, context);
      },
    );
  }

  Widget _buildWishlistItem(WishlistItem item, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2C1A3D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  item.sellerName ?? "Unknown Seller",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: Colors.red, size: 16),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  _removeFromWishlist(item, context);
                },
              ),
            ],
          ),
          SizedBox(height: 6),
          Center(child: Icon(Icons.book, size: 40, color: Colors.white)),
          SizedBox(height: 6),
          Center(
            child: Text(
              item.saleTradeTitle ?? "No Title",
              style: TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4),
          Text(
            item.saleTradePrice != null
                ? "${item.saleTradePrice!.toStringAsFixed(2)}€"
                : "N/A",
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          SizedBox(height: 4),
          Text(
            "Estado: ${item.saleTradeState ?? 'Desconhecido'}",
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (item.saleTradePrice != null)
                ElevatedButton(
                  onPressed: () {
                    _payForItem(item.saleTradeId, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  child: Text("PAY"),
                ),
              if (item.isAvailableForTrade == true)
                ElevatedButton(
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => TradeProposalModal(
                        saleTradeItem: item,
                        onTradeProposalSubmit: (isbnOffered, message) async {
                          String? token = await _getToken();
                          if (token != null) {
                            try {
                              await _marketplaceService.sendTradeProposal(
                                token,
                                item.saleTradeId,
                                isbnOffered,
                                message,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Trade proposal sent successfully!")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  child: Text("TRADE"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}