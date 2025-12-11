import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reader_frontend_app/models/user.dart';
import 'package:reader_frontend_app/services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '/headers/user_profile_header.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';


class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A),
      appBar: const UserProfileHeader(),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final contentWidth = isWideScreen ? 500.0 : double.infinity;

          return FutureBuilder<User>(
            future: UserProfileService.fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar o perfil: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text(
                    'Nenhum dado de usuário encontrado.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final user = snapshot.data!;

              if (!_isInitialized) {
                _usernameController.text = user.username;
                _nameController.text = user.nome;
                _emailController.text = user.email;
                _dobController.text = user.dbo;
                _bioController.text = user.bio;
                _isInitialized = true;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),
                          const Text(
                            'Atualizar Perfil do Usuário',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Inknut Antiqua',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildEditableField(
                            label: 'Username',
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 10),
                          _buildEditableField(
                            label: 'Nome',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 10),
                          _buildEditableField(
                            label: 'Bio',
                            controller: _bioController,
                          ),
                          const SizedBox(height: 10),
                          _buildEditableField(
                            label: 'Email',
                            controller: _emailController,
                          ),
                          const SizedBox(height: 10),
                          _buildEditableField(
                            label: 'Data de Nascimento',
                            controller: _dobController,
                            isDate: true,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _saveProfile();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25), // Bordas arredondadas
                              ),
                              backgroundColor: Colors.deepPurple, // Cor sólida do botão
                              elevation: 5, // Elevação do botão
                            ),
                            child: const Text(
                              'Salvar Alterações',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: isDate,
          style: const TextStyle(color: Colors.white), // Cor do texto alterada para branco
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Digite o $label',
            hintStyle: const TextStyle(color: Colors.grey), // Cor do texto de placeholder
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white), // Bordas quando o campo não está focado
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent), // Bordas ao focar no campo
            ),
          ),
          onTap: isDate
              ? () async {
                  DateTime currentDate = DateTime.now();
                  DateTime initialDate = DateTime.tryParse(controller.text) ??
                      currentDate;

                  if (initialDate.isAfter(currentDate)) {
                    initialDate = currentDate; // Previne datas no futuro.
                  }

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: currentDate,
                  );

                  if (pickedDate != null) {
                    setState(() {
                      controller.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                }
              : null,
        ),
      ],
    );
  }

  void _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = await authProvider.getCurrentUserId();

    final updatedProfile = {
      'username': _usernameController.text,
      'nome': _nameController.text,
      'email': _emailController.text,
      'nascimento': _dobController.text,
      'bio': _bioController.text,
    };

    try {
      String message = await UserProfileService.updateUserProfile(
        userId: userId,
        username: updatedProfile['username']!,
        nome: updatedProfile['nome']!,
        email: updatedProfile['email']!,
        nascimento: updatedProfile['nascimento']!,
        bio: updatedProfile['bio']!,
      );

      // Obtém o role do usuário
      final userRole = await AuthService.getUserRole();

      // Redireciona com base no role
      if (userRole == 'Autor') {
        Navigator.pushNamed(context, '/autor-home-page');
      } else if (userRole == 'Leitor') {
        Navigator.pushNamed(context, '/home');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o perfil: $error')),
      );
    }
  }
}
