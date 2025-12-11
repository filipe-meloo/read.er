import 'package:flutter/material.dart';
import '/views/personal_library_page.dart';
import '../searches/search_page.dart';
import '/views/marketplace_page.dart';
import '../auth/author_register_page.dart';
import '../auth/leitor_register_page.dart';
import '../auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomePageInitial(),
  '/autor-register': (context) => AutorRegisterView(),
  '/leitor-register': (context) => LeitorRegisterView(),
  '/login': (context) => LoginPage(),
  '/register': (context) => HomePageInitial(),
  '/library': (context) => PersonalLibraryPage(),
  '/search': (context) => SearchPage(),
  '/marketplace': (context) => MarketplacePage(),
};

class HomePageInitial extends StatelessWidget {
  const HomePageInitial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E0F29),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                "read.er",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),

      backgroundColor: const Color(0xFF1E0F29),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/leitor-register');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Registo como Leitor'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/autor-register');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Registo como Autor'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
