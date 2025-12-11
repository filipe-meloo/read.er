import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_frontend_app/dtos/search_book_dto.dart';
import 'package:reader_frontend_app/widgets/bookdetails/book_info_widget.dart';

void main() {
  group('BookInfoWidget', () {
    late SearchBookDto mockBook;

    setUp(() {
      mockBook = SearchBookDto(
        isbn: '123',
        title: 'Test Book',
        author: 'Test Author',
        coverUrl: 'https://test.com/cover.png',
        volumeId: '123',
        description: 'Test Book description',
      );
    });

    testWidgets('Exibe corretamente o título e o autor do livro', (WidgetTester tester) async {
      // Renderizar o widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookInfoWidget(book: mockBook),
          ),
        ),
      );

      // Verificar se o título é exibido corretamente
      expect(find.text('Test Book'), findsOneWidget);

      // Verificar se o autor é exibido corretamente
      expect(find.text('by Test Author'), findsOneWidget);
    });

    testWidgets('Aplica os estilos corretos no título e autor', (WidgetTester tester) async {
      // Renderizar o widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookInfoWidget(book: mockBook),
          ),
        ),
      );

      // Verificar estilos do título
      final titleText = tester.widget<Text>(find.text('Test Book'));
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.style?.color, Colors.white);

      // Verificar estilos do autor
      final authorText = tester.widget<Text>(find.text('by Test Author'));
      expect(authorText.style?.fontSize, 18);
      expect(authorText.style?.color, Colors.grey[400]);
    });
  });
}
