import 'package:flutter/material.dart';

class AdminAccessErrorPage extends StatelessWidget {
  const AdminAccessErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B3A), // Cor de fundo consistente
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0F29),
        elevation: 0,
        title: const Text(
          'Acesso Restrito',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login'); // Redireciona para a página de login
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline, // Ícone para indicar acesso restrito
              color: Colors.orange,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contas de Administrador não podem acessar esta aplicação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login'); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Voltar para o Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
