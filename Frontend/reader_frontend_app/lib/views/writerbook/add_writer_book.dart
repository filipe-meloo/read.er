import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/author_service.dart';

import '../../widgets/navigation_bars/bottom_navigation_bar_widget.dart';

class AddWriterBook extends m.StatefulWidget {
  const AddWriterBook({super.key});

  @override
  m.State<AddWriterBook> createState() => _AddWriterBookPageState();
}

class _AddWriterBookPageState extends m.State<AddWriterBook> {
  final TextEditingController _isbnController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  int currentIndex = 2;

  get isReader => false;

  void _addBook() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      setState(() {
        errorMessage = 'Por favor, insira um ISBN válido.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await AutorService.addBookByISBN(isbn);
      setState(() {
        isLoading = false;
      });
      m.Navigator.pop(context); 
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro ao adicionar o livro: $e';
      });
    }
  }

  @override
  m.Widget build(m.BuildContext context) {
    return m.Scaffold(
      backgroundColor: const m.Color(0xFF2C1B3A),
      appBar: m.AppBar(
        backgroundColor: const m.Color(0xFF3A2D58),
        title: const m.Text('Adicionar Livro', style: m.TextStyle(color: m.Colors.white)),
        leading: m.IconButton(
          icon: const m.Icon(m.Icons.arrow_back, color: m.Colors.white),
          onPressed: () {
            m.Navigator.pop(context);
          },
        ),
      ),
      body: m.Padding(
        padding: const m.EdgeInsets.all(16.0),
        child: m.Column(
          crossAxisAlignment: m.CrossAxisAlignment.start,
          children: [
            if (errorMessage.isNotEmpty)
              m.Padding(
                padding: const m.EdgeInsets.only(bottom: 16.0),
                child: m.Text(
                  errorMessage,
                  style: const m.TextStyle(color: m.Colors.red, fontSize: 14),
                ),
              ),
            const m.Text(
              "ISBN do Livro",
              style: m.TextStyle(color: m.Colors.white, fontSize: 18),
            ),
            m.SizedBox(height: 8),
            m.TextField(
              controller: _isbnController,
              style: const m.TextStyle(color: m.Colors.white),
              decoration: m.InputDecoration(
                filled: true,
                fillColor: const m.Color(0xFF3A2D58),
                border: const m.OutlineInputBorder(
                  borderRadius: m.BorderRadius.all(m.Radius.circular(8.0)),
                ),
                hintText: 'Digite o ISBN',
                hintStyle: const m.TextStyle(color: m.Colors.grey),
              ),
            ),
            m.SizedBox(height: 16),
            m.Center(
              child: m.ElevatedButton(
                onPressed: isLoading ? null : _addBook,
                style: m.ElevatedButton.styleFrom(
                  backgroundColor: m.Colors.purple,
                  foregroundColor: m.Colors.white,
                  padding: const m.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isLoading
                    ? const m.CircularProgressIndicator(color: m.Colors.white)
                    : const m.Text("Adicionar"),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isReader
          ? BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTabSelected: (index) {
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
              Navigator.pushReplacementNamed(context, '/AutorHomePage');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/marketplace');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/search');
              break;
          }
        },
        isReader: true,
      )
          : null, // Oculta a barra de navegação se não for leitor.
    );
  }
}
