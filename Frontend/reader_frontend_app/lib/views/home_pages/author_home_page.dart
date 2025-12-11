import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:reader_frontend_app/services/auth_provider.dart';
import 'package:reader_frontend_app/widgets/navbars/navbar.dart';
import 'package:reader_frontend_app/widgets/posts/comments_modal.dart';
import 'package:reader_frontend_app/headers/user_profile_header.dart';
import 'package:reader_frontend_app/services/author_service.dart';
import 'package:reader_frontend_app/services/post_service.dart';
import 'package:reader_frontend_app/services/user_profile_service.dart';
import 'package:reader_frontend_app/models/user.dart';
import 'package:reader_frontend_app/widgets/navigation_bars/bottom_navigation_bar_widget.dart';
import 'package:reader_frontend_app/services/config.dart';
import 'package:reader_frontend_app/views/writerbook/author_book_details_page.dart';
import '../../models/writer_book.dart';

class AutorHomePage extends m.StatefulWidget {
  
  const AutorHomePage({super.key});

  @override
  m.State<AutorHomePage> createState() => _AutorHomePageState();
}

class _AutorHomePageState extends m.State<AutorHomePage> {
  int followersCount = 0;
  int booksCount = 0;
  bool isLoading = true;
  late Future<List<Map<String, dynamic>>> postsFuture;
  late Future<List<WriterBook>> booksFuture;
  late Future<User> userFuture;
  bool isNavbarVisible = false;
  int currentIndex = 2;
  String errorMessage = '';

  get isReader => false;

  @override
  void initState() {
    super.initState();
    _fetchFollowersCount();
    postsFuture = AutorService.fetchUserPosts();
    userFuture = UserProfileService.fetchUserProfile();
    postsFuture = AutorService.fetchUserPosts();
    booksFuture = AutorService.fetchApprovedBooks();
    _fetchBooksCount();
  }



  Future<void> _fetchFollowersCount() async {
    try {
      final count = await AutorService.fetchFollowersCount();
      setState(() {
        followersCount = count;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Erro ao buscar seguidores: $e");
    }
  }

  Future<void> _fetchBooksCount() async {
    try {
      final count = await AutorService.getNumberOfBooks();
      setState(() {
        booksCount = count; // Atualiza o contador de livros
        isLoading = false; // Finaliza o carregamento
      });
    } catch (e) {
      setState(() {
        booksCount = 0; // Em caso de erro, zera o contador de livros
        isLoading = false; // Finaliza o carregamento
      });
      print("Erro ao buscar livros: $e"); // Pode ser interessante logar o erro
    }
  }

  void _toggleNavbar() {
    setState(() {
      isNavbarVisible = !isNavbarVisible;
    });
  }

  @override
  m.Widget build(m.BuildContext context) {
    return m.Scaffold(
      backgroundColor: const m.Color(0xFF2C1B3A),
      appBar: const UserProfileHeader(),
      body: m.Stack(
        children: [
          m.Column(
            children: [
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
                            friendRequestsCount: 0,
                            hasOwnedCommunities: false,
                            isReader: isReader,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              m.Expanded(
                child: m.FutureBuilder<User>(
                  future: userFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == m.ConnectionState.waiting) {
                      return const m.Center(
                          child: m.CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return m.Center(
                        child: m.Text(
                          'Erro ao carregar o perfil: ${snapshot.error}',
                          style: const m.TextStyle(
                              color: m.Colors.red, fontSize: 16),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const m.Center(
                        child: m.Text(
                          'Nenhum dado de usuário encontrado.',
                          style: m.TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final user = snapshot.data!;

                    return m.SingleChildScrollView(
                      child: m.Padding(
                        padding: const m.EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: m.Column(
                          crossAxisAlignment: m.CrossAxisAlignment.start,
                          children: [
                            m.Row(
                              crossAxisAlignment: m.CrossAxisAlignment.start,
                              children: [
                                m.CircleAvatar(
                                  radius: 40,
                                  backgroundColor: m.Colors.purple,
                                  child: m.Icon(m.Icons.person,
                                      color: m.Colors.white, size: 40),
                                ),
                                m.SizedBox(width: 16),
                                m.Expanded(
                                  child: m.Column(
                                    crossAxisAlignment:
                                        m.CrossAxisAlignment.start,
                                    children: [
                                      m.Text(
                                        user.username,
                                        style: m.TextStyle(
                                          color: m.Colors.white,
                                          fontSize: 24,
                                          fontWeight: m.FontWeight.bold,
                                        ),
                                      ),
                                      m.SizedBox(height: 8),
                                      m.Text(
                                        user.bio ??
                                            "Nenhuma biografia disponível.",
                                        style: m.TextStyle(
                                          color: m.Colors
                                              .white, // Tornar o texto branco para contraste
                                          fontSize:
                                              16, // Aumentar o tamanho da fonte
                                          fontStyle: m.FontStyle
                                              .italic, // Adicionar itálico
                                        ),
                                      ),
                                      m.SizedBox(height: 16),
                                      m.Row(
                                        mainAxisAlignment:
                                            m.MainAxisAlignment.start,
                                        children: [
                                          _buildStatColumn(
                                            isLoading
                                                ? '...'
                                                : followersCount.toString(),
                                            "Followers",
                                          ),
                                          m.SizedBox(width: 16),
                                          _buildStatColumn(
                                            isLoading
                                                ? '...'
                                                : booksCount.toString(),
                                            "Books",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            m.SizedBox(height: 32),
                            m.Row(
                              children: [
                                m.Text(
                                  "Livros Pendentes",
                                  style: m.TextStyle(
                                    color: m.Colors.white,
                                    fontSize: 18,
                                    fontWeight: m.FontWeight.bold,
                                  ),
                                ),
                                const m.Spacer(),
                                m.ElevatedButton.icon(
                                  onPressed: () {
                                    // Navegar para a página de livros pendentes
                                    m.Navigator.pushNamed(
                                        context, '/pending-books');
                                  },
                                  icon: const m.Icon(m.Icons.hourglass_empty,
                                      size: 18),
                                  label: const m.Text("Ver Pendentes"),
                                  style: m.ElevatedButton.styleFrom(
                                    foregroundColor: m.Colors.white,
                                    backgroundColor: m.Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            m.Divider(color: m.Colors.white, thickness: 1),
                            m.Row(
                              children: [
                                m.Text(
                                  "My Books",
                                  style: m.TextStyle(
                                    color: m.Colors.white,
                                    fontSize: 18,
                                    fontWeight: m.FontWeight.bold,
                                  ),
                                ),
                                const m.Spacer(),
                                m.ElevatedButton.icon(
                                  onPressed: () {
                                    // Substituindo o caminho correto
                                    m.Navigator.pushNamed(
                                        context, '/add-writer-book');
                                  },
                                  icon: const m.Icon(m.Icons.add, size: 18),
                                  label: const m.Text("Adicionar"),
                                  style: m.ElevatedButton.styleFrom(
                                    foregroundColor: m.Colors.white,
                                    backgroundColor: m.Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            m.SizedBox(
                              height:
                                  200, // Altura fixa para o carrossel de livros
                              child: m.FutureBuilder<List<WriterBook>>(
                                future: booksFuture,
                                builder: (context, booksSnapshot) {
                                  if (booksSnapshot.connectionState ==
                                      m.ConnectionState.waiting) {
                                    return const m.Center(
                                        child: m.CircularProgressIndicator());
                                  } else if (booksSnapshot.hasError) {
                                    return m.Center(
                                      child: m.Text(
                                        'Erro ao carregar os livros: ${booksSnapshot.error}',
                                        style: const m.TextStyle(
                                            color: m.Colors.red, fontSize: 16),
                                      ),
                                    );
                                  } else if (!booksSnapshot.hasData ||
                                      booksSnapshot.data!.isEmpty) {
                                    return const m.Center(
                                      child: m.Text(
                                        'Nenhum livro encontrado.',
                                        style: m.TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }

                                  final books = booksSnapshot.data!;
                                  return m.ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: books.length,
                                    itemBuilder: (context, index) {
                                      final book = books[index];
                                      return _buildBookCard(book);
                                    },
                                  );
                                },
                              ),
                            ),
                            m.SizedBox(height: 32),
                            m.Text(
                              "Posts",
                              style: m.TextStyle(
                                color: m.Colors.white,
                                fontSize: 18,
                                fontWeight: m.FontWeight.bold,
                              ),
                            ),
                            m.SizedBox(height: 16),
                            m.FutureBuilder<List<Map<String, dynamic>>>(
                              future: postsFuture,
                              builder: (context, postsSnapshot) {
                                if (postsSnapshot.connectionState ==
                                    m.ConnectionState.waiting) {
                                  return const m.Center(
                                      child: m.CircularProgressIndicator());
                                } else if (postsSnapshot.hasError) {
                                  return m.Center(
                                    child: m.Text(
                                      'Erro ao carregar os posts: ${postsSnapshot.error}',
                                      style: const m.TextStyle(
                                          color: m.Colors.red, fontSize: 16),
                                    ),
                                  );
                                } else if (!postsSnapshot.hasData ||
                                    postsSnapshot.data!.isEmpty) {
                                  return const m.Center(
                                    child: m.Text(
                                      'Nenhum post encontrado.',
                                      style: m.TextStyle(fontSize: 16),
                                    ),
                                  );
                                }

                                final posts = postsSnapshot.data!;

                                return m.ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const m.NeverScrollableScrollPhysics(),
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    final post = posts[index];
                                    return _buildPostCard(post);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: isReader
          ? BottomNavigationBarWidget(
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
              Navigator.pushReplacementNamed(context, '/AutorHomePage');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/marketplace');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/search');
              break;
          }
        },
        isReader: true,
      )
          : null, // Oculta a barra de navegação se não for leitor.
    );
  }

  m.Widget _buildStatColumn(String value, String label) {
    return m.Column(
      crossAxisAlignment: m.CrossAxisAlignment.center,
      children: [
        m.Text(
          value,
          style: m.TextStyle(
            color: m.Colors.white,
            fontSize: 18,
            fontWeight: m.FontWeight.bold,
          ),
        ),
        m.Text(
          label,
          style: m.TextStyle(
            color: m.Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  m.Widget _buildBookCard(WriterBook book) {
    final encodedImageUrl = Uri.encodeComponent(
        'http://books.google.com/books/content?id=${book.volumeId}&printsec=frontcover&img=1&zoom=1&source=gbs_api');
    final coverUrl =
        '$BASE_URL/api/PersonalLibrary/book-cover-proxy?imageUrl=$encodedImageUrl';

    return m.FutureBuilder<Map<String, String>>(
      future: AuthProvider.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == m.ConnectionState.waiting) {
          return const m.Center(child: m.CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const m.Icon(m.Icons.broken_image, size: 50);
        }

        return m.Padding(
          padding: const m.EdgeInsets.symmetric(horizontal: 8.0),
          child: m.GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuthorBookDetailsPage(book: book),
                ),
              );
            },
            child: m.Card(
              color: const m.Color(0xFF3A2D58),
              margin: const m.EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: m.Image.network(
                coverUrl,
                headers: snapshot.data,
                fit: m.BoxFit.cover,
                width: 120, // Ajuste de largura para manter o layout
                errorBuilder: (context, error, stackTrace) {
                  return const m.Icon(m.Icons.broken_image, size: 50);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  m.Widget _buildPostCard(Map<String, dynamic> post) {
    return m.Card(
      color: const m.Color(0xFF3A2D58),
      margin: const m.EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: m.Padding(
        padding: const m.EdgeInsets.all(8.0),
        child: m.Column(
          crossAxisAlignment: m.CrossAxisAlignment.start,
          children: [
            m.Text(
              post['bookTitle'] ?? 'Untitled',
              style: const m.TextStyle(
                color: m.Colors.white,
                fontSize: 16,
                fontWeight: m.FontWeight.bold,
              ),
            ),
            m.SizedBox(height: 8),
            m.Text(
              post['content'] ?? 'No content',
              style: const m.TextStyle(
                color: m.Colors.white,
                fontSize: 14,
              ),
            ),
            m.SizedBox(height: 8),
            m.Text(
              'By ${post['username'] ?? 'Unknown User'}',
              style: const m.TextStyle(
                color: m.Colors.white70,
                fontSize: 12,
                fontStyle: m.FontStyle.italic,
              ),
            ),
            m.SizedBox(height: 8),
            m.Row(
              mainAxisAlignment: m.MainAxisAlignment.start,
              children: [
                m.IconButton(
                  icon: const m.Icon(
                    m.Icons.thumb_up,
                    color: m.Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _reactToPost(post['postId'], 'like');
                  },
                ),
                m.Text(
                  '${post['numberOfReactions'] ?? 0}',
                  style: const m.TextStyle(color: m.Colors.white),
                ),
                m.SizedBox(width: 16),
                m.IconButton(
                  icon: const m.Icon(
                    m.Icons.comment,
                    color: m.Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _commentOnPost(post['postId']);
                  },
                ),
                m.Text(
                  '${post['numberOfComments'] ?? 0} comments',
                  style: const m.TextStyle(color: m.Colors.white),
                ),
                m.SizedBox(width: 16),
                m.IconButton(
                  icon: const m.Icon(
                    m.Icons.share,
                    color: m.Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _sharePost(post['postId']);
                  },
                ),
                m.Text(
                  '${post['numberOfReposts'] ?? 0} shares',
                  style: const m.TextStyle(color: m.Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reactToPost(int postId, String reactionType) async {
    try {
      await PostService.reactToPost(postId, reactionType);
      AutorService.fetchUserPosts();
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
          onCommentAdded: AutorService.fetchUserPosts,
        );
      },
    );
  }

  void _sharePost(int postId) async {
    try {
      await PostService.sharePost(postId);
      AutorService.fetchUserPosts();
    } catch (e) {
      setState(() {
        errorMessage = "Erro ao partilhar o post: $e";
      });
    }
  }
}
