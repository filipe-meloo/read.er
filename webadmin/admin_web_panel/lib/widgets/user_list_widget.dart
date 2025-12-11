import 'package:flutter/material.dart';

class UserListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String keyField;
  final String valueField;

  UserListWidget({
    required this.data,
    required this.title,
    required this.keyField,
    required this.valueField,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "Sem utilizadores para exibir.",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(
                    item[keyField]?.toString() ??
                        "Sem Nome", // Prevenir valores nulos
                  ),
                  subtitle: Text(
                    "${item[valueField]?.toString() ?? "Sem Dados"}", // Prevenir valores nulos
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
