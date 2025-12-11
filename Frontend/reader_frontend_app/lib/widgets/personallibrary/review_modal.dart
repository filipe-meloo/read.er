import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/config.dart';

class ReviewModal extends StatefulWidget {
  final String isbn;

  const ReviewModal({super.key, required this.isbn});

  @override
  _ReviewModalState createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A avaliação deve ser entre 1 e 5.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final url = '$BASE_URL/api/Books/rateBook';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'ASDASDASD'
        },
        body: json.encode({
          'isbn': widget.isbn,
          'rating': _rating,
          'comment': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avaliação adicionada com sucesso.')),
        );
        Navigator.pop(context, true); // Close modal and return success
      } else {
        throw Exception('Erro ao enviar avaliação: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar avaliação: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Avaliar Livro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Dê uma nota entre 1 e 5:'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Comentário',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Close modal without action
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? CircularProgressIndicator()
              : Text('Enviar Avaliação'),
        ),
      ],
    );
  }
}
