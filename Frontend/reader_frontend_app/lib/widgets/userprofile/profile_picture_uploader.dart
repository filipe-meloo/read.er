import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/config.dart';

class ProfilePictureUploader extends StatefulWidget {
  final Function(String)? onUploadComplete;

  const ProfilePictureUploader({super.key, this.onUploadComplete});

  @override
  _ProfilePictureUploaderState createState() => _ProfilePictureUploaderState();
}

class _ProfilePictureUploaderState extends State<ProfilePictureUploader> {
  File? _image;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _uploadedImageUrl = pickedFile.path;
          });
        }
      } else {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print("Erro ao selecionar a imagem: $e");
      _showMessage("Erro ao selecionar a imagem. Tente novamente.");
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null && _uploadedImageUrl == null) {
      _showMessage("Nenhuma imagem selecionada para upload.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final dio = Dio();
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      _showMessage("Token inválido ou não encontrado. Faça login novamente.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      FormData formData = FormData.fromMap({
        "file": _image != null
            ? await MultipartFile.fromFile(_image!.path, filename: "profile_picture.jpg")
            : MultipartFile.fromBytes(await XFile(_uploadedImageUrl!).readAsBytes(), filename: "profile_picture.jpg"),
      });

      final response = await dio.post(
        "$BASE_URL/api/UserProfile/upload-profile-picture",
        data: formData,
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "multipart/form-data",
        }),
      );

      setState(() {
        _uploadedImageUrl = response.data['profilePictureUrl'];
        _isLoading = false;
      });

      if (widget.onUploadComplete != null) {
        widget.onUploadComplete!(_uploadedImageUrl!);
      }

      _showMessage("Upload bem-sucedido!");
      print("Upload bem-sucedido: ${response.data}");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_image != null || _uploadedImageUrl != null)
          kIsWeb
              ? Image.network(
                  _uploadedImageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  _image!,
                  height: 200,
                )
        else
          const Text("Nenhuma imagem selecionada."),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Column(
            children: [
              // Botão para escolher a imagem
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Escolher Imagem"),
              ),
              const SizedBox(height: 10), // Espaço entre os botões
              // Botão para fazer upload
              ElevatedButton(
                onPressed: _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Fazer Upload"),
              ),
            ],
          ),
      ],
    );
  }
}
