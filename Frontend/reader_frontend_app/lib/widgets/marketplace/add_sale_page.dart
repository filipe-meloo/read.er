import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/marketplace_service.dart';

class AddSalePage extends StatefulWidget {
  final VoidCallback onSaleAdded; // Callback para notificar a adição

  const AddSalePage({super.key, required this.onSaleAdded}); // Construtor para receber o callback

  @override
  _AddSalePageState createState() => _AddSalePageState();
}

class _AddSalePageState extends State<AddSalePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController desiredBookController = TextEditingController();
  bool isForSale = false;
  bool isForTrade = false;
  final MarketplaceService marketplaceService = MarketplaceService();

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  void _submitSale() async {
    String title = titleController.text;
    String? priceText = priceController.text;
    String? desiredBookTitle = desiredBookController.text;

    if (title.isEmpty || (!isForSale && !isForTrade)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    double? price;
    if (isForSale) {
      if (double.tryParse(priceText) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Preço inválido para venda.")),
        );
        return;
      }
      price = double.parse(priceText);
    }

    try {
      // Obter o token do usuário
      String? token = await _getToken();
      if (token == null) {
        throw Exception("Usuário não autenticado! Faça login novamente.");
      }

      // Criar a venda usando o título do livro (não ISBN)
      await marketplaceService.createSale(
        token: token,
        title: title, // Enviar o título do livro
        price: price,
        isForSale: isForSale,
        isForTrade: isForTrade,
        desiredBook: isForTrade ? desiredBookTitle : null, // Título do livro desejado, se aplicável
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Venda adicionada com sucesso!")),
      );

      widget.onSaleAdded(); // Chama o callback para notificar a atualização
      Navigator.pop(context); // Voltar à página anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao adicionar venda: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adicionar Venda ou Troca"),
        backgroundColor: Color(0xFF1E0F29),
      ),
      backgroundColor: Color(0xFF1E0F29),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Título do Livro",
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Color(0xFF2C1A3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isForSale,
                    onChanged: (value) {
                      setState(() {
                        isForSale = value!;
                      });
                    },
                    activeColor: Colors.purple,
                  ),
                  Text("Disponível para Venda", style: TextStyle(color: Colors.white)),
                ],
              ),
              if (isForSale)
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: "Preço (opcional para troca)",
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Color(0xFF2C1A3D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isForTrade,
                    onChanged: (value) {
                      setState(() {
                        isForTrade = value!;
                      });
                    },
                    activeColor: Colors.purple,
                  ),
                  Text("Disponível para Troca", style: TextStyle(color: Colors.white)),
                ],
              ),
              if (isForTrade)
                TextField(
                  controller: desiredBookController,
                  decoration: InputDecoration(
                    labelText: "Livro desejado para troca",
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Color(0xFF2C1A3D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: Text("Adicionar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
