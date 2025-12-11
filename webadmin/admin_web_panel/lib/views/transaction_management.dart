import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class TransactionManagementView extends StatefulWidget {
  @override
  _TransactionManagementViewState createState() =>
      _TransactionManagementViewState();
}

class _TransactionManagementViewState extends State<TransactionManagementView> {
  late Future<List<dynamic>> _futureTransactions;

  @override
  void initState() {
    super.initState();
    _futureTransactions = AdminService.fetchTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _futureTransactions = AdminService.fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestão de Transações")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro: ${snapshot.error}",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma transação encontrada.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    "ID da Transação: ${transaction['id']}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ISBN: ${transaction['isbn'] ?? 'Não informado'}"),
                      Text(
                          "Vendedor (ID): ${transaction['sellerId'] ?? 'Não informado'}"),
                      Text(
                          "Comprador (ID): ${transaction['buyerId'] ?? 'Não informado'}"),
                      Text(
                          "Preço: \$${transaction['price']?.toStringAsFixed(2) ?? '0.00'}"),
                      Text(
                          "Data de Conclusão: ${transaction['dateCompleted'] ?? 'Desconhecida'}"),
                      Text(
                          "ID Original: ${transaction['originalSaleTradeId'] ?? 'Não informado'}"),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "delete") {
                        try {
                          await AdminService.deleteTransaction(
                              transaction['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Transação excluída!"),
                            ),
                          );
                          _refreshTransactions(); // Atualiza a lista após exclusão
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erro ao excluir: $error"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "delete",
                        child: Text("Excluir Transação"),
                      ),
                    ],
                    icon: Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
