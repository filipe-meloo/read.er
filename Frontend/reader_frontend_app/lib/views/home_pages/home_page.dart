import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../widgets/navigation_bars/bottom_navigation_bar_widget.dart';
import '../../widgets/navbars/navbar.dart';
import '../../widgets/posts/comments_modal.dart';
import '../../widgets/posts/create_post_widget.dart';
import '../../widgets/posts/post_list_widget.dart';
import '/services/post_service.dart';
import '/services/friendship_service.dart';
import '/models/post_model.dart';
import '/headers/home_page_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PostModel> posts = [];
  bool isLoading = true;
  String? errorMessage;
  int friendRequestsCount = 0;
  int currentIndex = 2;
  bool isNavbarVisible = false;
  bool hasOwnedCommunities = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _fetchFriendRequestsCount();
    _checkOwnedCommunities();

  }


  Future<void> _checkOwnedCommunities() async {
    try {
      final communities = await CommunityService().fetchUserOwnedCommunities();
      setState(() {
        hasOwnedCommunities = communities.isNotEmpty; // Define como true se houver comunidades
      });
    } catch (e) {
      print("Erro ao verificar comunidades: $e");
      setState(() {
        hasOwnedCommunities = false; // Garante que seja false em caso de erro
      });
    }
  }
  void _toggleNavbar() {
    setState(() {
      isNavbarVisible = !isNavbarVisible;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final fetchedPosts = await PostService.fetchPosts();
      setState(() {
        posts = fetchedPosts;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar posts: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFriendRequestsCount() async {
    try {
      final requests = await FriendshipService.fetchFriendRequests();
      setState(() {
        friendRequestsCount = requests.length;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao carregar solicitações de amizade: $e";
      });
    }
  }

  void _reactToPost(int postId, String reactionType) async {
    try {
      await PostService.reactToPost(postId, reactionType);
      _loadPosts();
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao reagir ao post: $e";
      });
    }
  }

  void _commentOnPost(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsModal(
          postId: postId,
          onCommentAdded: _loadPosts,
        );
      },
    );
  }

  void _sharePost(int postId) async {
    try {
      await PostService.sharePost(postId);
      _loadPosts();
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao partilhar o post: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C1B3A),
      body: Stack(
        children: [
          Column(
            children: [
              HomePageHeader(
                onMenuTapped: _toggleNavbar,
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : PostListWidget(
                  posts: posts,
                  onReact: _reactToPost,
                  onComment: _commentOnPost,
                  onShare: _sharePost,
                ),
              ),
            ],
          ),
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
          if (errorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CreatePostWidget(
              onPostCreated: _loadPosts,
            ),
          );
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTabSelected: (index) {
          setState(() {
            currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/library');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/community');
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
