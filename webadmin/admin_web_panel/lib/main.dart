import 'package:admin_web_panel/services/auth_service.dart';
import 'package:admin_web_panel/views/post_management.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'middleware/auth_middleware.dart'; // Middleware para verificar permissões
import 'views/admin_dashboard.dart';
import 'views/login_view.dart';
import 'views/error_view.dart';
import 'views/user_management.dart';
import 'views/community_management.dart';
import 'views/reports_management.dart';
import 'views/book_approval_management.dart';
import 'views/transaction_management.dart';
import 'views/unauthorized_page.dart'; // Página de acesso negado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AdminCenter',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthService.isLoggedIn(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return LoginView();
                  } else {
                    return LoginView(); 
                  }
                },
              ),
            );
                  case '/admin-dashboard':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthService.isLoggedIn(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return AdminDashboard();
                  } else {
                    return LoginView();  // Redireciona para o login se o usuário não estiver logado
                  }
                },
              ),
            );

          case '/user-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return UserManagement();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/community-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return CommunityManagementView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/reports-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return ReportsManagementView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/book-approval-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return BookApprovalManagementView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/transaction-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return TransactionManagementView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/post-management':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return PostManagementView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          case '/logout':
            return MaterialPageRoute(
              builder: (context) => FutureBuilder(
                future: AuthMiddleware.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data == true) {
                    return LoginView();
                  } else {
                    return UnauthorizedPage();
                  }
                },
              ),
            );

          default:
            return MaterialPageRoute(builder: (context) => ErrorView());
        }
      },
    );
  }
}
