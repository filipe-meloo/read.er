import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../services/friendship_service.dart';
import '../../widgets/navigation_bars/bottom_navigation_bar_widget.dart';
import '../../widgets/communities/user_communities_modal.dart';
import '../../widgets/navbars/navbar.dart';
import 'discover_page.dart';
import 'communities_main_page.dart';
import '../../headers/community_header.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  _CommunitiesPageState createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;
  bool isNavbarVisible = false;
  int friendRequestsCount = 0;
  bool hasOwnedCommunities = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFriendRequestsCount();
    _checkOwnedCommunities();
  }

  void _onTabChanged(int index) {
    setState(() {
      _tabController.index = index; // Alterar aba dentro do botão Communities
    });
  }

  void _toggleNavbar() {
    setState(() {
      isNavbarVisible = !isNavbarVisible;
    });
  }

  Future<void> _fetchFriendRequestsCount() async {
    final requests = await FriendshipService.fetchFriendRequests();
    setState(() {
      friendRequestsCount = requests.length;
    });
  }

  Future<void> _checkOwnedCommunities() async {
    try {
      final communities = await CommunityService().fetchUserOwnedCommunities();
      setState(() {
        hasOwnedCommunities =
            communities.isNotEmpty; // Define como true se houver comunidades
      });
    } catch (e) {
      print("Erro ao verificar comunidades: $e");
      setState(() {
        hasOwnedCommunities = false; // Garante que seja false em caso de erro
      });
    }
  }

  Future<void> _showUserCommunitiesModal() async {
    try {
      final communities = await CommunityService.fetchUserCommunities();
      final formattedCommunities = communities
          .map((community) =>
      {
        'id': community.id,
        'name': community.name,
        'description': community.description,
      })
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return UserCommunitiesModal(
            communities: formattedCommunities,
            onLeaveCommunity: (communityId) async {
              await _leaveCommunity(communityId);
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar comunidades: $e')),
      );
    }
  }

  Future<void> _leaveCommunity(int communityId) async {
    try {
      await CommunityService.leaveCommunity(communityId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saiu da comunidade com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair da comunidade: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommunityHeader(
        title: "read.er | Clubs",
        onSearchTap: () {
          print("Pesquisar nas comunidades...");
        },
        onMembersTap: _showUserCommunitiesModal,
        onMenuTapped: _toggleNavbar,
        currentIndex: _tabController.index,
        // Índice da aba atual
        onTabChanged: _onTabChanged,
      ),
      backgroundColor: const Color(0xFF2C1B3A),
      body: Stack(
        children: [
          // Conteúdo principal
          TabBarView(
            controller: _tabController,
            children: [
              const CommunitiesMainPage(),
              const DiscoverPage(),
            ],
          ),
          // Navbar visível sobre o conteúdo
          if (isNavbarVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleNavbar, // Fecha o Navbar ao clicar fora dele
                child: Container(
                  color: Colors.black54, // Fundo semitransparente
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 250,
                      color: const Color(0xFF2C1B3A),
                      child: NavbarContent(
                        friendRequestsCount: friendRequestsCount,
                        hasOwnedCommunities: hasOwnedCommunities,
                        isReader: true,

                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/library');
              break;
            case 1:
            // Mantenha na mesma página, pois já estamos aqui
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/marketplace');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/search');
              break;
          }
        }, isReader: true,
      ),
    );
  }
}
