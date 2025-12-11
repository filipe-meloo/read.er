import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale_trade.dart';
import '../models/sale_trade_offer.dart';
import '../models/sale_trade_review.dart';
import '../models/wishlist_item.dart';
import 'config.dart';

class MarketplaceService {
  final String baseUrl = '$BASE_URL/api';

  Future<void> decideSaleTradeOffer(
      String token, int offerId, bool accept, {String? message}) async {
    final url = '$BASE_URL/api/saletrade/offer/$offerId/decision';

    // Corpo da requisição
    final body = jsonEncode({
      'accept': accept,
      'message': message ?? "", // Inclua o campo Message, mesmo que vazio
    });

    print('Request URL: $url');
    print('Request Headers: ${{
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    }}');
    print('Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to decide offer: ${response.body}');
      }
    } catch (e) {
      print('Error deciding offer: $e');
      rethrow; // Repropaga o erro para o Flutter tratar
    }
    }


  Future<void> removeFromWishlist(String token, int saleTradeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wishlist/remove'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({'saleTradeId': saleTradeId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao remover da wishlist: ${response.body}');
    }
  }

  Future<List<SaleTradeOffer>> fetchOffers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saletrade/offers-decisions'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> offersJson = json.decode(response.body);
      return offersJson.map((offer) {
        try {
          return SaleTradeOffer.fromJson(offer);
        } catch (e) {
          print("Erro ao processar oferta: $offer, Erro: $e");
          return null; // Retorna `null` para evitar exceções
        }
      }).whereType<SaleTradeOffer>().toList(); // Remove valores nulos
    } else {
      throw Exception("Erro ao carregar ofertas: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> fetchTradeOfferWithReview(int tradeOfferId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwtToken');

    if (token == null || token.isEmpty) {
      throw Exception("Token is null or empty");
    }

    print("Token fetched: $token");

    final response = await http.get(
      Uri.parse('$baseUrl/Review/tradeOfferWithReview/$tradeOfferId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("Response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      print("Response body: ${response.body}");
      throw Exception("Failed to fetch trade offer: ${response.body}");
    }

    final data = jsonDecode(response.body);
    print("Parsed JSON: $data"); // Adicione este log para depurar o JSON recebido

    return {
      "review": data['review'] != null
          ? SaleTradeReview.fromJson(data['review'])
          : null,
    };
  }


  Future<void> rateTradeOffer(String token, int tradeOfferId, int rating, String comment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Review/rateTradeOffer'),

      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "tradeOfferId": tradeOfferId,
        "rating": rating,
        "comment": comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to submit rating: ${response.body}");
    }
  }

  Future<List<WishlistItem>> fetchWishlist(String token) async {
    // Buscar a wishlist
    final wishlistResponse = await http.get(
      Uri.parse('$baseUrl/Wishlist/list'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (wishlistResponse.statusCode != 200) {
      throw Exception('Failed to load wishlist');
    }

    List<dynamic> wishlistData = json.decode(wishlistResponse.body);

    // Buscar friends-sales para associar os SaleTrades
    final saleTradesResponse = await http.get(
      Uri.parse('$baseUrl/saletrade/friends-sales'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (saleTradesResponse.statusCode != 200) {
      throw Exception('Failed to load sale trades from friends');
    }

    List<dynamic> saleTradesData = json.decode(saleTradesResponse.body);

    // Mapear todas as SaleTrades para facilitar a busca
    final saleTradesMap = {
      for (var saleTrade in saleTradesData)
        saleTrade['id']: SaleTrade.fromJson(saleTrade),
    };

    // Criar os itens da wishlist com o desiredBookTitle da SaleTrade
    List<WishlistItem> wishlistItems = wishlistData.map((json) {
      final wishlistItem = WishlistItem.fromJson(json);

      // Associe o desiredBookTitle a partir da SaleTrade correspondente
      final relatedSaleTrade = saleTradesMap[wishlistItem.saleTradeId];
      if (relatedSaleTrade != null) {
        wishlistItem.saleTradeDesiredBookTitle = relatedSaleTrade.desiredBookTitle;
      }

      return wishlistItem;
    }).toList();

    return wishlistItems;
  }


  Future<Map<String, dynamic>> createCheckoutSession(String token, int saleTradeId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Payment/create-checkout-session"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({"SaleTradeId": saleTradeId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to create checkout session: ${response.body}");
    }
  }

  Future<List<SaleTrade>> fetchMarketplaceSales(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saletrade/friends-sales'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SaleTrade.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load marketplace sales');
    }
  }

  Future<void> addToWishlist(String token, int saleTradeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Wishlist/addToWishlist'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "saleTradeId": saleTradeId, // ID da venda para adicionar à wishlist
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao adicionar à wishlist: ${response.body}');
    }
  }

  Future<List<SaleTrade>> fetchOwnSales(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/saletrade/my-sales'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SaleTrade.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load your sales');
    }
  }

  Future<void> createSale({
    required String token,
    required String title,
    double? price,
    required bool isForSale,
    required bool isForTrade,
    String? desiredBook,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/saletrade/create'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "isbn": title,
        // Enviar o título como "isbn" (o backend processará isso)
        "price": price,
        "isAvailableForSale": isForSale,
        "isAvailableForTrade": isForTrade,
        "isbnDesiredBook": desiredBook,
        // Desejado para troca, se aplicável
        "notes": "Venda adicionada pelo usuário",
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao adicionar venda: ${response.body}');
    }
  }

  Future<void> sendTradeProposal(String token,
      int saleTradeId,
      String isbnOffered,
      String message,) async {
    final response = await http.post(
      Uri.parse(
          "$baseUrl/Saletrade/$saleTradeId/trade-offer"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "isbnOfferedBook": isbnOffered,
        "message": message,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create trade proposal: ${response.body}");
    }
  }
}
