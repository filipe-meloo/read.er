import 'package:flutter/material.dart';

class UnloggedMarketplaceNavbar extends StatelessWidget implements PreferredSizeWidget {
  const UnloggedMarketplaceNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Layout para telas menores
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'read.er',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontFamily: 'Inknut Antiqua',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'Register') {
                        Navigator.pushNamed(context, '/register');
                      } else if (value == 'Login') {
                        Navigator.pushNamed(context, '/login');
                      } else {
                        print(value);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'Home',
                        child: Text('Home'),
                      ),
                      const PopupMenuItem(
                        value: 'My Library',
                        child: Text('My Library'),
                      ),
                      const PopupMenuItem(
                        value: 'Marketplace',
                        child: Text('Marketplace'),
                      ),
                      const PopupMenuItem(
                        value: 'Communities',
                        child: Text('Communities'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'Register',
                        child: Text('Register'),
                      ),
                      const PopupMenuItem(
                        value: 'Login',
                        child: Text('Login'),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Layout para telas maiores
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'read.er',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontFamily: 'Inknut Antiqua',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Flexible(
                    child: Wrap(
                      spacing: 20.0, // Espaçamento entre os botões
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home');
                          },
                          child: const Text(
                            'Home',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/myLibrary');
                          },
                          child: const Text(
                            'My Library',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/marketplace');
                          },
                          child: const Text(
                            'Marketplace',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/communities');
                          },
                          child: const Text(
                            'Communities',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        // Botões de Registro e Login
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD9D9D9), width: 2),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD9D9D9),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
