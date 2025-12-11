import 'package:flutter/material.dart';
import 'package:reader_frontend_app/models/sale_trade_offer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/navigation_bars/bottom_navigation_bar_widget.dart';
import '../widgets/marketplace/add_sale_page.dart';
import '../widgets/marketplace/market_section.dart';
import '../widgets/marketplace/sales_section.dart';
import '../widgets/marketplace/wishlist_section.dart';
import '../widgets/marketplace/offers_sections.dart'; // Nova seção para as ofertas
import '../headers/marketplace_header.dart';
import '../models/sale_trade.dart';
import '../models/wishlist_item.dart';
import '../services/marketplace_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controlador para as abas
  List<WishlistItem> wishlistItems = [];
  List<SaleTrade> marketItems = [];
  List<SaleTrade> salesItems = [];
  List<SaleTradeOffer> offerItems = []; // Lista para armazenar as ofertas recebidas
  bool isLoading = true;
  String? errorMessage;
  int currentIndex = 3;

  final MarketplaceService _marketplaceService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Duas abas
    fetchMarketplaceData();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  Future<void> fetchMarketplaceData() async {
    try {
      String? token = await _getToken();
      if (token == null) {
        throw Exception("Token não encontrado. Faça login novamente.");
      }

      await Future.wait([
        _loadWishlist(token),
        _loadMarketplaceSales(token),
        _loadOwnSales(token),
        _loadOffers(token), // Nova função para carregar ofertas
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadWishlist(String token) async {
    try {
      var wishlist = await _marketplaceService.fetchWishlist(token);
      setState(() {
        wishlistItems = wishlist.map((item) {
          // Atualizar a propriedade isAvailableForTrade ao carregar
          item.isAvailableForTrade = marketItems.any(
                (marketItem) => marketItem.id == item.saleTradeId && marketItem.isAvailableForTrade,
          );
          return item;
        }).toList();
      });
    } catch (e) {
      print('Erro ao carregar a wishlist: $e');
    }
  }


  Future<void> _loadMarketplaceSales(String token) async {
    try {
      var market = await _marketplaceService.fetchMarketplaceSales(token);
      setState(() {
        marketItems = market;
      });
    } catch (e) {
      print('Erro ao carregar marketplace sales: $e');
    }
  }

  Future<void> _loadOwnSales(String token) async {
    try {
      var sales = await _marketplaceService.fetchOwnSales(token);
      setState(() {
        salesItems = sales;
      });
    } catch (e) {
      print('Erro ao carregar as suas vendas: $e');
    }
  }

  Future<void> _loadOffers(String token) async {
    try {
      var offers = await _marketplaceService.fetchOffers(token);
      print("Ofertas recebidas: $offers");

      setState(() {
        offerItems = offers;
      });
    } catch (e) {
      print("Erro ao carregar as ofertas: $e");
    }
  }

  void reloadData() async {
    // Função para recarregar todos os dados
    setState(() {
      isLoading = true;
    });
    await fetchMarketplaceData();
  }

  Future<void> _reloadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found!");

      final sales = await _marketplaceService.fetchOwnSales(token);
      final offers = await _marketplaceService.fetchOffers(token);

      setState(() {
        salesItems = sales;
        offerItems = offers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error reloading data: $e");
    }
  }

  void onTabSelected(int index) {
    if (currentIndex == index) return;
    setState(() {
      currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/library');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/community');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/marketplace');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/search');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E0F29),
      appBar: MarketplaceHeader(
        onSearch: () {
        },
        tabController: _tabController, // Passa o controlador de abas
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Página "Market"
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wishlistItems.isNotEmpty)
                    WishlistSection(
                      wishlistItems: wishlistItems,
                      onWishlistUpdated: () async {
                        String? token =
                        await _getToken(); // Recuperar o token
                        if (token != null) {
                          await _loadWishlist(token); // Atualizar a wishlist
                        } else {
                          print("Token não encontrado");
                        }
                      },
                    ),
                  SizedBox(height: 16),
                  MarketSection(
                    marketItems: marketItems,
                    reloadData: reloadData, // Passar função de recarregar
                  ),
                  SizedBox(height: 16),
                  SalesSection(
                    salesItems: salesItems,
                    onAddSale: _navigateToAddSalePage,
                  ),
                ],
              ),
            ),
          ),

          // Página "Offers"
          OffersSection(
            offerItems: offerItems,
            wishlistItems: [],
            marketItems: [],
            marketplaceService: _marketplaceService,
            onUpdate: _reloadData, // Passa o callback de recarregamento
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected, isReader: true,
      ),
    );
  }

  void _navigateToAddSalePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSalePage(
          onSaleAdded: () async {
            await _loadOwnSales(await _getToken() ?? ""); // Recarrega as vendas
          },
        ),
      ),
    );
  }
}
