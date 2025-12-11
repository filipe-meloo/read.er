import 'package:flutter/material.dart';
import '../../models/sale_trade.dart';

class SalesSection extends StatelessWidget {
  final List<SaleTrade> salesItems;
  final VoidCallback onAddSale; // Callback para o botão "Adicionar"

  const SalesSection({
    super.key,
    required this.salesItems,
    required this.onAddSale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Sales",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onAddSale,
              child: Text(
                "Adicionar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildHorizontalList(context),
      ],
    );
  }

  Widget _buildHorizontalList(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Filtrar apenas itens disponíveis para venda ou troca
    final availableSalesItems = salesItems.where((item) {
      return item.isAvailableForSale || item.isAvailableForTrade;
    }).toList();

    return SizedBox(
      height: 200, // Altura padrão dos cards
      child: availableSalesItems.isEmpty
          ? Center(
        child: Text(
          "Nenhuma venda disponível.",
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => SizedBox(width: 16), // Espaçamento entre itens
        itemCount: availableSalesItems.length,
        itemBuilder: (context, index) {
          final item = availableSalesItems[index];
          return _buildSaleItem(item, context);
        },
      ),
    );
  }

  Widget _buildSaleItem(SaleTrade item, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.4, // Largura proporcional à tela
      decoration: BoxDecoration(
        color: Color(0xFF2C1A3D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  "Você", // Indicando que é do usuário
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Icon(Icons.book, size: screenWidth * 0.08, color: Colors.white),
          SizedBox(height: 6),
          Text(
            item.title ?? "Título não disponível",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            item.price != null ? "${item.price!.toStringAsFixed(2)}€" : "N/A",
            style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.035),
          ),
          if (item.isAvailableForTrade) ...[
            SizedBox(height: 8),
            Text(
              "Disponível para troca",
              style: TextStyle(color: Colors.orange, fontSize: screenWidth * 0.03),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}