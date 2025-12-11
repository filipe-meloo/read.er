import 'package:flutter/material.dart';
import '/services/post_service.dart';

class CreatePostWidget extends StatefulWidget {
  final Function onPostCreated;

  const CreatePostWidget({super.key, required this.onPostCreated});

  @override
  _CreatePostWidgetState createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _bookTitleController = TextEditingController();
  String _selectedPostType = 'Critica'; // Tipo padrão
  bool isPosting = false;

  void _submitPost() async {
    if (_postController.text.isEmpty) return;

    setState(() {
      isPosting = true;
    });

    try {
      await PostService.createPost(
        content: _postController.text,
        tipoPublicacao: _selectedPostType,
        tituloLivro: _bookTitleController.text.isNotEmpty ? _bookTitleController.text : null,
      );
      widget.onPostCreated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar post: $e')),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        color: Color(0xFF1E0F29),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _postController,
              maxLength: 1000,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escreva seu post...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Color(0xFF2C1B3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _bookTitleController,
              decoration: InputDecoration(
                labelText: 'Título do livro (opcional)',
                labelStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Color(0xFF2C1B3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedPostType,
              dropdownColor: Color(0xFF2C1B3A),
              items: ['Critica', 'Recomendacao', 'Citacao'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPostType = newValue!;
                });
              },
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: Text(isPosting ? 'Postando...' : 'Postar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
