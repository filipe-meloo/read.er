import 'package:flutter/material.dart';

class LoggedNavbar extends StatelessWidget implements PreferredSizeWidget {
  const LoggedNavbar({super.key});

  void _logoutAndRedirect(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

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
                      switch (value) {
                        case 'Home':
                          Navigator.pushNamed(context, '/home');
                          break;
                        case 'My Library':
                          Navigator.pushNamed(context, '/myLibrary');
                          break;
                        case 'Marketplace':
                          Navigator.pushNamed(context, '/marketplace');
                          break;
                        case 'Communities':
                          Navigator.pushNamed(context, '/communities');
                          break;
                        case 'Logout':
                          _logoutAndRedirect(context);
                          break;
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
                        value: 'Logout',
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Row(
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
                  const SizedBox(width: 20),
                  Expanded(
                    child: Wrap(
                      spacing: 20.0,
                      runSpacing: 10.0,
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/');
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: constraints.maxWidth * 0.2,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.black),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Pesquisar...',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/my-profile');
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(0xFFEADDFF),
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.person, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => _logoutAndRedirect(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black),
                          ),
                          child: const Text(
                            'Logout',
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
  Size get preferredSize => const Size.fromHeight(80.0);
}
