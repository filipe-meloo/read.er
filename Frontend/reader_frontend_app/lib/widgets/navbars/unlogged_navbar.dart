import 'package:flutter/material.dart';

class UnloggedNavBar extends StatelessWidget implements PreferredSizeWidget {
  const UnloggedNavBar({super.key});

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
                      // Lógica ao clicar nos itens do menu
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
                      spacing: 8.0, 
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
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.black),
                          ),
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
  Size get preferredSize => const Size.fromHeight(60.0);
}
