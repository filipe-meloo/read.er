import 'package:flutter/material.dart';
import 'package:reader_frontend_app/models/wishlist_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../models/sale_trade.dart';
import '../../models/sale_trade_offer.dart';
import '../../models/sale_trade_review.dart';
import '../../services/marketplace_service.dart';

class OffersSection extends StatefulWidget {
  final List<SaleTradeOffer> offerItems;
  final MarketplaceService marketplaceService;
  final List<WishlistItem> wishlistItems;
  final List<SaleTrade> marketItems;
  final VoidCallback onUpdate; // Adiciona o callback para atualização

  const OffersSection({super.key, 
    required this.offerItems,
    required this.marketplaceService,
    required this.wishlistItems,
    required this.marketItems,
    required this.onUpdate, // Callback para atualizar
  });

  @override
  _OffersSectionState createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  late List<WishlistItem> wishlistItems;
  late List<SaleTrade> marketItems = [];
  late List<SaleTradeOffer> madePendingOffers = [];
  late List<SaleTradeOffer> receivedPendingOffers = [];
  late List<SaleTradeOffer> madeNegotiationHistory = [];
  late List<SaleTradeOffer> receivedNegotiationHistory = [];
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }


  void _showRatingDialog(BuildContext context, int tradeOfferId) {
    final TextEditingController commentController = TextEditingController();
    int rating = 3; // Valor inicial

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Rate Trade Offer"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select a rating:"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: index < rating ? Colors.yellow : Colors.grey,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1; // Atualiza o estado local
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(labelText: "Comment"),
                    maxLines: 2,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Submit"),
              onPressed: () async {
                await _submitRating(tradeOfferId, rating, commentController.text.trim());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Mostra o diálogo com os detalhes da avaliação existente
  void _showReviewDetails(BuildContext context, int rating, String comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Review Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Rating: $rating/5",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Comment: $comment",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _submitRating(int tradeOfferId, int rating, String comment) async {
    if (comment.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment is required!")),
      );
      return;
    }

    final token = await _getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are not authenticated!")),
      );
      return;
    }

    try {
      await widget.marketplaceService.rateTradeOffer(
        token,
        tradeOfferId, // Certifique-se de que está correto
        rating,
        comment,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rating submitted successfully!")),
      );

      // Atualiza o histórico de negociação após a avaliação
      widget.onUpdate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting rating: $e")),
      );
    }
  }


  void _categorizeOffers() {
    if (currentUserId == null) {
      return;
    }

    madePendingOffers = widget.offerItems
        .where((offer) =>
    offer.status == "Pendente" && offer.idUser == currentUserId)
        .toList();

    receivedPendingOffers = widget.offerItems
        .where((offer) =>
    offer.status == "Pendente" && offer.saleTradeOwnerId == currentUserId)
        .toList();

    madeNegotiationHistory = widget.offerItems
        .where((offer) =>
    offer.status != "Pendente" && offer.idUser == currentUserId)
        .toList();

    receivedNegotiationHistory = widget.offerItems
        .where((offer) =>
    offer.status != "Pendente" && offer.saleTradeOwnerId == currentUserId)
        .toList();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }


  Future<void> _initializeUserId() async {
    final token = await _getToken();

    if (token != null) {
      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        int userId = int.tryParse(decodedToken['userId'].toString()) ?? -1;

        if (userId != -1) {
          setState(() {
            currentUserId = userId;
          });
          _categorizeOffers();
        } else {
          throw Exception("Invalid user ID in token.");
        }
      } catch (e) {
        print("Error decoding token: $e");
        setState(() {
          currentUserId = null;
        });
      }
    } else {
      print("Token not found");
      setState(() {
        currentUserId = null;
      });
    }
  }

  Future<void> _makeDecision(BuildContext context, int offerId, bool accept) async {
    final token = await _getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are not authenticated!")),
      );
      return;
    }

    try {
      await widget.marketplaceService.decideSaleTradeOffer(token, offerId, accept);

      if (accept) {
        final acceptedOffer = receivedPendingOffers.firstWhere((offer) => offer.idOffer == offerId);

        setState(() {
          receivedPendingOffers.removeWhere((offer) => offer.idSaleTrade == acceptedOffer.idSaleTrade);
          receivedNegotiationHistory.add(acceptedOffer);
          widget.marketItems.removeWhere((item) => item.id == acceptedOffer.idSaleTrade);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Offer accepted successfully!")),
        );

        // Chamar o callback para atualizar os dados no componente pai
        widget.onUpdate();
      } else {
        setState(() {
          receivedPendingOffers.removeWhere((offer) => offer.idOffer == offerId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Offer declined successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing the decision: $e")),
      );
    }
  }

// Recarregar Wishlist
  Future<void> _reloadWishlist() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found!");

      final updatedWishlist = await widget.marketplaceService.fetchWishlist(token);
      setState(() {
        wishlistItems = updatedWishlist; // Atualiza a lista local
      });
    } catch (e) {
      print("Error reloading wishlist: $e");
    }
  }

// Recarregar Marketplace
  Future<void> _reloadMarket() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found!");

      final updatedMarket = await widget.marketplaceService.fetchMarketplaceSales(token);
      setState(() {
        marketItems = updatedMarket; // Atualiza a lista local
      });
    } catch (e) {
      print("Error reloading market: $e");
    }
  }

  Widget _buildOfferCard(SaleTradeOffer offer) {
    return Card(
      color: Color(0xFF2C1A3D),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do livro oferecido
            Text(
              offer.offeredBookTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Informações do user que ofereceu
            Text(
              "Offered by: ${offer.idUser}",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),

            // Exibe o status da oferta
            if (offer.status != "Pendente") ...[
              Text(
                "Status: ${offer.status}",
                style: TextStyle(
                  color: offer.status == "Aceita" ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              if (offer.status == "Aceita" && offer.idUser == currentUserId)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.star, color: Colors.yellow),
                    onPressed: () async {
                      try {
                        final reviewResponse = await _fetchReview(offer.idOffer);

                        if (reviewResponse != null && reviewResponse['review'] != null) {
                          final review = reviewResponse['review'] as SaleTradeReview;

                          // Mostrar os detalhes da avaliação existente
                          _showReviewDetails(context, review.rating, review.comment);
                        } else {
                          // Abrir o modal para criar nova avaliação
                          _showRatingDialog(context, offer.idOffer);
                        }
                      } catch (e) {
                        print("Error fetching review: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to fetch review: $e")),
                        );
                      }
                    },
                  ),
                ),
            ] else ...[
              // Exibe a mensagem se a oferta estiver pendente
              Text(
                "Message: ${offer.message ?? "No message provided"}",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],

            // Mostra os botões de decisão apenas para o proprietário da oferta
            if (offer.status == "Pendente" && offer.saleTradeOwnerId == currentUserId)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await _makeDecision(context, offer.idOffer, true);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await _makeDecision(context, offer.idOffer, false);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  Future<Map<String, dynamic>?> _fetchReview(int tradeOfferId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception("User is not authenticated");
      }

      // Log do token e ID da oferta
      print("Fetching review for TradeOffer ID: $tradeOfferId with token: $token");

      final response = await widget.marketplaceService.fetchTradeOfferWithReview(tradeOfferId);

      // Log da resposta
      print("Response: ${response.toString()}");

      if (response.containsKey('review')) {
        return response; // Retorna o mapa com a avaliação
      }
      return null; // Caso não exista uma avaliação associada
    } catch (e) {
      print("Error in _fetchReview: $e");
      return null;
    }
  }

  Widget _buildCarousel(String subTitle, List<SaleTradeOffer> offers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subTitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
            ],
          ),
        ),
        SizedBox(height: 8),
        offers.isEmpty
            ? Text(
          "No $subTitle available.",
          style: TextStyle(color: Colors.white60),
        )
            : SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: _buildOfferCard(offer),
              );
            },
          ),
        ),
        Divider(color: Colors.white24, thickness: 0.5),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pending Offers",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildCarousel("Made", madePendingOffers),
          _buildCarousel("Received", receivedPendingOffers),
          Divider(color: Colors.white, height: 16, thickness: 1),
          Text(
            "Negotiation History",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildCarousel("Made", madeNegotiationHistory),
          _buildCarousel("Received", receivedNegotiationHistory),
        ],
      ),
    );
  }
}
