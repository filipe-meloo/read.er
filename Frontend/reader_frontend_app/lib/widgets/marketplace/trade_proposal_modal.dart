import 'package:flutter/material.dart';
import '../../models/wishlist_item.dart';

class TradeProposalModal extends StatelessWidget {
  final WishlistItem saleTradeItem;
  final Function(String, String) onTradeProposalSubmit;

  const TradeProposalModal({super.key, 
    required this.saleTradeItem,
    required this.onTradeProposalSubmit,
  });




  @override
  Widget build(BuildContext context) {
    String isbnOffered = ""; // Campo de texto inicial vazio
    String tradeMessage = ""; // Mensagem inicial

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          color: Color(0xFF2C1A3D), // Cor de fundo consistente com o app
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Propose Trade",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Desired Book:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Text(
                    saleTradeItem.saleTradeDesiredBookTitle ?? "N/A",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "Your Book to Offer:",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              TextField(
                style: TextStyle(color: Colors.white), // Texto branco para contraste
                onChanged: (value) {
                  setState(() {
                    isbnOffered = value; // Atualizar o valor do ISBN oferecido
                  });
                },
                decoration: InputDecoration(
                  hintText: "Enter the Book Title",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF3B2A50), // Cor de fundo ajustada
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                style: TextStyle(color: Colors.white), // Texto branco para contraste
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    tradeMessage = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Add a message (optional)",
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF3B2A50), // Cor de fundo ajustada
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: isbnOffered.isNotEmpty
                    ? () {
                  onTradeProposalSubmit(isbnOffered, tradeMessage);
                  Navigator.pop(context); // Fecha o modal
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text("Make Trade Proposal"),
              ),
            ],
          ),
        );
      },
    );
  }
}
