import 'package:flutter/material.dart';

import '../../widgets/navbars/unlogged_navbar.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnloggedNavBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/leitor-register');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Registo como Leitor'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/autor-register');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Registo como Autor'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}