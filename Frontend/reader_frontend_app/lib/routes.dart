import 'package:flutter/material.dart';
import 'package:reader_frontend_app/views/writerbook/add_writer_book.dart';
import 'package:reader_frontend_app/views/auth/admin_access_error_page.dart';
import 'package:reader_frontend_app/views/auth/author_register_page.dart';
import 'package:reader_frontend_app/views/auth/leitor_register_page.dart';
import 'package:reader_frontend_app/views/auth/login_page.dart';
import 'package:reader_frontend_app/views/auth/register_page.dart';
import 'package:reader_frontend_app/views/writerbook/author_book_details_page.dart';
import 'package:reader_frontend_app/views/book_details_page.dart';
import 'package:reader_frontend_app/views/communities/communities_page.dart';
import 'package:reader_frontend_app/views/communities/community_page.dart';
import 'package:reader_frontend_app/views/communities/my_communities_page.dart';

import 'package:reader_frontend_app/views/home_pages/home_page.dart';
import 'package:reader_frontend_app/views/home_pages/home_page_initial.dart';
import 'package:reader_frontend_app/views/home_pages/author_home_page.dart';
import 'package:reader_frontend_app/views/marketplace_page.dart';

import 'package:reader_frontend_app/views/writerbook/pending_book.dart';
import 'package:reader_frontend_app/views/notifications_page.dart';
import 'package:reader_frontend_app/views/profile/FriendRequestsPage.dart';
import 'package:reader_frontend_app/views/profile/OtherUserProfilePage.dart';
import 'package:reader_frontend_app/views/profile/UpdateProfilePage.dart';
import 'package:reader_frontend_app/views/profile/UserProfilePage.dart';

import 'package:reader_frontend_app/views/recover_password_page.dart';
import 'package:reader_frontend_app/views/searches/search_page.dart';
import 'package:reader_frontend_app/views/searches/search_users_page_state.dart';
import 'package:reader_frontend_app/widgets/userprofile/friends_list_modal.dart';

import 'dtos/search_book_dto.dart';

import 'models/writer_book.dart';
import 'views/personal_library_page.dart';
import '/widgets/bookdetails/book_details_model.dart';


// Rotas estáticas
final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomePageInitial(),
  '/pending-books': (context) => PendingBooks(),
  '/admin-page': (context) => AdminAccessErrorPage(),
  '/add-writer-book': (context) => AddWriterBook(),
  '/autor-home-page': (context) => AutorHomePage(),
  '/author-book-details': (context) => AuthorBookDetailsPage(
    book: ModalRoute.of(context)!.settings.arguments as WriterBook,
  ),
  '/login': (context) => LoginPage(),
  '/logout': (context) => HomePageInitial(),
  '/register': (context) => Register(),
  '/autor-register': (context) => AutorRegisterView(),
  '/leitor-register': (context) => LeitorRegisterView(),
  '/community': (context) => CommunitiesPage(),
  '/home': (context) => HomePage(),
  '/library': (context) => PersonalLibraryPage(),
  '/search': (context) => SearchPage(),
  '/marketplace': (context) => MarketplacePage(),
  '/profile': (context) => UserProfilePage(),
  '/profile/update': (context) => UpdateProfilePage(),
  '/friend-requests': (context) => FriendRequestsPage(),
  '/friend-list': (context) => FriendsListModal(friends: [], onRemoveFriend: (int ) {  },),
  '/user-profile': (context) => UserProfilePage(),
  '/notifications': (context) => NotificationsPage(),
  '/autor-home-page': (context) => AutorHomePage(),
  '/search-users': (context) => SearchUsersPage(),
  '/my-communities': (context) => MyCommunitiesPage(),
  '/recover-password': (context) => ForgotPasswordPage(),
};
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (settings.name != null && settings.name!.startsWith('/community/')) {
    // Extrai o ID da comunidade da URL
    final id = int.tryParse(settings.name!.replaceFirst('/community/', ''));

    // Verifica se o ID é válido
    if (id == null) {
      return MaterialPageRoute(
        builder: (context) => NotFoundPage(),
      );
    }

    // Extrai os argumentos passados (opcionais)
    final arguments = settings.arguments as Map<String, dynamic>?;

    final communityName = arguments?['name'] ?? 'Comunidade';
    final communityDescription = arguments?['description'] ?? 'Descrição não disponível';
    final communityImage = arguments?['image'] ?? '';

    return MaterialPageRoute(
      builder: (context) => CommunityPage(
        communityId: id,
        communityName: communityName,
        communityDescription: communityDescription,
        communityImage: communityImage,
      ),
      settings: RouteSettings(name: '/community/$id'),
    );
  }

  if (settings.name != null && settings.name!.startsWith('/book-details/')) {
    final isbn = settings.name!.replaceFirst('/book-details/', '');
    final arguments = settings.arguments as Map<String, dynamic>?;

    final book = arguments?['book'] as SearchBookDto?;
    final action = arguments?['action'] as BookDetailsAction?;

    return MaterialPageRoute(
      builder: (context) => BookDetailsPage(
        isbn: isbn,
        fromPersonalLibrary: action == BookDetailsAction.reviewBook,
        fromSearch: action == BookDetailsAction.addToLibrary,
      ),
      settings: RouteSettings(name: '/book-details/$isbn'),
    );
  }



  if (settings.name == '/other-user-profile') {
    final userId = settings.arguments as int?;
    if (userId == null) {
      return MaterialPageRoute(
        builder: (context) => NotFoundPage(),
      );
    }
    return MaterialPageRoute(
      builder: (context) => OtherUserProfilePage(userId: userId),
    );
  }

  return MaterialPageRoute(
    builder: (context) => NotFoundPage(),
  );
}


class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Página não encontrada')),
      body: Center(
        child: Text('A rota solicitada não existe.'),
      ),
    );
  }
}
