import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class ReportsManagementView extends StatefulWidget {
  @override
  _ReportsManagementViewState createState() => _ReportsManagementViewState();
}

class _ReportsManagementViewState extends State<ReportsManagementView> {
  late Future<List<dynamic>> _futureReports;

  @override
  void initState() {
    super.initState();
    _futureReports = AdminService.fetchReportedPosts();
  }

  void _refreshReports() {
    setState(() {
      _futureReports = AdminService.fetchReportedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestão de Reports")),
      body: FutureBuilder<List<dynamic>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar reports: ${snapshot.error}",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Text(
                "Nenhum report encontrado.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    report["bookTitle"] ?? "Sem título associado",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Conteúdo: ${report["conteudo"] ?? "Sem conteúdo"}"),
                      Text(
                          "Tipo: ${report["tipoPublicacao"] ?? "Desconhecido"}"),
                      Text("Data: ${report["dataCriacao"] ?? "Desconhecida"}"),
                      Text("Status: ${report["status"] ?? "Desconhecido"}"),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        if (value == "resolve") {
                          await AdminService.resolveReport(report['id'],
                              remove: false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Report resolvido sem remover o post!"),
                            ),
                          );
                        } else if (value == "remove") {
                          await AdminService.resolveReport(report['id'],
                              remove: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("Report resolvido e post removido!"),
                            ),
                          );
                        }
                        _refreshReports(); // Atualiza a lista após a ação
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erro ao realizar a ação: $error"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "resolve",
                        child: Text("Resolver sem remover"),
                      ),
                      PopupMenuItem(
                        value: "remove",
                        child: Text("Resolver e remover"),
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
