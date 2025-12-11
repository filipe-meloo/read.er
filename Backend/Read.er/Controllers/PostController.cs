using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes.Post;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Posts;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PostController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly INotificationService _notificationService;

    public PostController(AppDbContext context, IGoogleBooksService bookService,
        INotificationService notificationService)
    {
        _context = context;
        _googleBooksService = bookService;
        _notificationService = notificationService;
    }

    /// <summary>
    /// Handles the creation of a new post by an authenticated user.
    /// </summary>
    /// <param name="model">Data transfer object containing the details of the post to be created.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok if the post is created successfully.
    /// - Unauthorized if the user is not authenticated.
    /// - BadRequest if the post content exceeds the allowed length or if the ISBN is invalid.
    /// - NotFound if the specified book is not found.
    /// </returns>
    [HttpPost("create")]
    public async Task<IActionResult> CreatePost([FromBody] CreatePostDto model)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Utilizador não autenticado.");
        var userId = int.Parse(userIdClaim.Value);

        if (model.Conteudo.Length > 1000)
            return BadRequest("O conteúdo da publicação excede o limite de 1000 caracteres.");

        string isbn = null;
        if (!string.IsNullOrEmpty(model.TituloLivro))
        {
            isbn = await _googleBooksService.GetIsbnByTitle(model.TituloLivro);
            if (isbn == "ISBN não encontrado") return NotFound("Livro não encontrado na Google Books API.");
        }

        if (!string.IsNullOrEmpty(isbn) && (isbn.Length < 10 || isbn.Length > 13))
            return BadRequest("O ISBN deve ter entre 10 e 13 caracteres.");

        if (model.IdCommunity.HasValue)
        {
            var member = await _context.UserCommunity
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == model.IdCommunity && !uc.IsPending);

            if (member == null) return BadRequest("O utilizador não é membro da comunidade ou ainda está pendente.");

            if (model.TopicId.HasValue)
            {
                var communityTopic = await _context.CommunityTopics
                    .FirstOrDefaultAsync(ct => ct.CommunityId == model.IdCommunity && ct.TopicId == model.TopicId);

                if (communityTopic == null) return NotFound("Tópico não encontrado na comunidade.");

                if (communityTopic.IsBlocked) return BadRequest("Tópico bloqueado na comunidade. Tente outro tópico.");
            }
        }

        var post = new Post
        {
            IdUser = userId,
            Conteudo = model.Conteudo,
            DataCriacao = DateTime.Now,
            TipoPublicacao = model.TipoPublicacao,
            Isbn = isbn,
            BookTitle = model.TituloLivro,
            CommunityId = model.IdCommunity,
            TopicId = model.TopicId
        };

        _context.Posts.Add(post);
        await _context.SaveChangesAsync();

        if (model.IdCommunity.HasValue)
            await _notificationService.NotifyCommunityMembersOfNewPost(model.IdCommunity.Value, userId, post.Conteudo);
        else
            await _notificationService.NotifyFriendsOfNewPost(userId, post.Conteudo);

        return Ok("Publicação criada com sucesso.");
    }

    /// <summary>
    /// Allows an authenticated user to react to an existing post.
    /// </summary>
    /// <param name="postId">The identifier of the post to which the reaction is applied.</param>
    /// <param name="reactionType">The type of reaction to be recorded.</param>
    /// <returns>
    /// An asynchronous operation that returns an IActionResult with possible outcomes:
    /// - Ok if the reaction is successfully registered.
    /// - Unauthorized if the user is not authenticated.
    /// - NotFound if the post is not found.
    /// - BadRequest if the post is a shared post or if the user is not a member of the post's community.
    /// </returns>
    [HttpPost("ReactToPost")]
    public async Task<IActionResult> ReactToPost(int postId, ReactionType reactionType)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Utilizador não autenticado.");
        var userId = int.Parse(userIdClaim.Value);

        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == postId);
        if (post == null) return NotFound("Post não encontrado.");

        if (post.OriginalPostId != null) return BadRequest("Não é possível reagir a um post que é uma partilha.");

        if (post.CommunityId.HasValue)
        {
            var member = await _context.UserCommunity
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == post.CommunityId && !uc.IsPending);

            if (member == null) return BadRequest("O utilizador não é membro da comunidade ou ainda está pendente.");
        }

        var existingReaction = await _context.PostReactions
            .FirstOrDefaultAsync(r => r.PostId == postId && r.UserId == userId);

        if (existingReaction != null)
        {
            existingReaction.ReactionType = reactionType;
            existingReaction.ReactionDate = DateTime.Now;
        }
        else
        {
            var postReaction = new PostReaction
            {
                PostId = postId,
                UserId = userId,
                ReactionType = reactionType,
                ReactionDate = DateTime.Now
            };
            _context.PostReactions.Add(postReaction);
        }

        await _context.SaveChangesAsync();

        await _notificationService.NotifyAuthorOfReaction(postId, userId, reactionType);

        return Ok("Reação registrada com sucesso.");
    }

    /// <summary>
    /// Shares an existing post to the personal feed of an authenticated user.
    /// </summary>
    /// <param name="postId">The identifier of the post to be shared.</param>
    /// <param name="communityId">Optional. The identifier of the community to share the post within, if applicable.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok if the post is shared successfully to the user's personal feed.
    /// - Unauthorized if the user is not authenticated.
    /// - NotFound if the original post is not found.
    /// - BadRequest if the original post is marked inappropriate, already a shared post, or already shared by the user.
    /// </returns>
    [HttpPost("share")]
    public async Task<IActionResult> SharePost(int postId, int? communityId = null)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Utilizador não autenticado.");
        var userId = int.Parse(userIdClaim.Value);

        var originalPost = await _context.Posts.FindAsync(postId);
        if (originalPost == null) return NotFound("Post original não encontrado.");
        if (originalPost.IsInappropriate) return BadRequest("Não é possível reagir a um post marcado como impróprio.");

        if (originalPost.OriginalPostId != null)
            return BadRequest("Não é possível partilhar um post que já é uma partilha.");

        if (communityId.HasValue)
        {
            var member = await _context.UserCommunity
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId && !uc.IsPending);
            if (member == null) return BadRequest("O utilizador não é membro da comunidade ou ainda está pendente.");

            if (originalPost.CommunityId != communityId)
                return BadRequest("O post original não pertence a esta comunidade.");

            var existingCommunitySharedPost = await _context.Posts
                .FirstOrDefaultAsync(p =>
                    p.OriginalPostId == postId && p.IdUser == userId && p.CommunityId == communityId);
            if (existingCommunitySharedPost != null)
                return BadRequest("O utilizador já partilhou este post na comunidade.");

            var sharedCommunityPost = new Post
            {
                OriginalPostId = originalPost.Id,
                IdUser = userId,
                Conteudo = originalPost.Conteudo,
                DataCriacao = DateTime.Now,
                TipoPublicacao = originalPost.TipoPublicacao,
                Isbn = originalPost.Isbn,
                CommunityId = communityId,
                TopicId = originalPost.TopicId
            };

            _context.Posts.Add(sharedCommunityPost);
            await _context.SaveChangesAsync();

            return Ok("Post partilhado com sucesso na comunidade.");
        }

        var existingPersonalSharedPost = await _context.Posts
            .FirstOrDefaultAsync(p => p.OriginalPostId == postId && p.IdUser == userId && p.CommunityId == null);
        if (existingPersonalSharedPost != null)
            return BadRequest("O utilizador já partilhou este post no seu feed pessoal.");

        var sharedPersonalPost = new Post
        {
            OriginalPostId = originalPost.Id,
            IdUser = userId,
            Conteudo = originalPost.Conteudo,
            DataCriacao = DateTime.Now,
            TipoPublicacao = originalPost.TipoPublicacao,
            Isbn = originalPost.Isbn
        };

        _context.Posts.Add(sharedPersonalPost);
        await _context.SaveChangesAsync();

        return Ok("Post partilhado com sucesso no seu feed pessoal.");
    }

    /// <summary>
    /// Marks a post as reported based on its identifier.
    /// </summary>
    /// <param name="postId">The identifier of the post to be reported.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok if the post is reported successfully.
    /// - NotFound if the post is not found in the database.
    /// </returns>
    [HttpPatch("report/{postId}")]
    public async Task<IActionResult> ReportPost(int postId)
    {
        var post = await _context.Posts.FindAsync(postId);
        if (post == null) return NotFound("Post não encontrado.");

        if (post.Solved)
            return BadRequest("Post já foi reportado");
        
        post.IsReported = true;
        _context.Posts.Update(post);
        await _context.SaveChangesAsync();

        return Ok("Post denunciado com sucesso.");
    }

    /// <summary>
    /// Retrieves the list of posts that do not belong to the authenticated user.
    /// </summary>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok with a list of posts, excluding those created by the authenticated user.
    /// - Unauthorized if the user is not authenticated.
    /// </returns>
    [HttpGet("list")]
    public async Task<IActionResult> GetPostList()
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Utilizador não autenticado.");
        var userId = int.Parse(userIdClaim.Value);

        // Filtra os posts que não pertencem ao utilizador autenticado
        var combinedPosts = await _context.Posts
            .Include(p => p.User)
            .Where(p => p.IdUser != userId) // Exclui os posts do utilizador autenticado
            .ToListAsync();

        var postDtos = combinedPosts.Select(post => new PostDto
        {
            PostId = post.Id,
            UserId = post.IdUser,
            Username = post.User.Nome,
            Content = post.Conteudo,
            OriginalPostId = post.OriginalPostId,
            OriginalUsername = post.OriginalPostId != null
                ? _context.Posts
                    .Where(op => op.Id == post.OriginalPostId)
                    .Select(op => op.User.Nome)
                    .FirstOrDefault()
                : null,
            Isbn = post.Isbn,
            BookTitle = post.BookTitle, // Agora diretamente do modelo
            NumberOfReactions = _context.PostReactions.Count(r => r.PostId == post.Id),
            NumberOfComments = _context.Comments.Count(c => c.PostId == post.Id)
        }).ToList();

        return Ok(postDtos);
    }

    /// <summary>
    /// Retrieves the list of posts created by the authenticated user.
    /// </summary>
    /// <returns>
    /// An asynchronous task that returns an IActionResult, which can be:
    /// - Ok containing a list of PostDto objects if the user is authenticated and posts are found.
    /// - Unauthorized if the user is not authenticated.
    /// </returns>
    [HttpGet("user-posts")]
    public async Task<IActionResult> GetUserPosts()
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null)
        {
            return Unauthorized(401);
        }

        int userId = int.Parse(userIdClaim.Value);

        var userPosts = await _context.Posts
            .Where(p => p.IdUser == userId)
            .Include(p => p.OriginalPost) // Inclui informações sobre o post original (se for um repost)
            .OrderByDescending(p => p.DataCriacao) // Ordena por data de criação (mais recente primeiro)
            .ToListAsync();

        var postsWithTitle = userPosts.Select(post => new PostDto
        {
            PostId = post.Id,
            Content = post.Conteudo,
            Username = _context.Users
                .Where(u => u.Id == post.IdUser)
                .Select(u => u.Nome)
                .FirstOrDefault(),
            OriginalPostId = post.OriginalPostId,
            OriginalUsername = post.OriginalPost?.User?.Nome,
            Isbn = post.Isbn,
            BookTitle = post.BookTitle, // Agora diretamente do modelo
            NumberOfReactions = _context.PostReactions.Count(r => r.PostId == post.Id),
            NumberOfComments = _context.Comments.Count(c => c.PostId == post.Id)
        }).ToList();

        return Ok(postsWithTitle);
    }

    /// <summary>
    /// Allows an authenticated user to comment on a specified post.
    /// </summary>
    /// <param name="postId">The identifier of the post to be commented on.</param>
    /// <param name="model">The data transfer object containing the content of the comment.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok if the comment is added successfully.
    /// - Unauthorized if the user is not authenticated.
    /// - BadRequest if the comment content is missing.
    /// - NotFound if the specified post is not found.
    /// </returns>
    [HttpPost("CommentOnPost")]
    public async Task<IActionResult> CommentOnPost(int postId, [FromBody] CommentDto model)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null)
        {
            return Unauthorized("Utilizador não autenticado.");
        }
        int userId = int.Parse(userIdClaim.Value);

        if (string.IsNullOrEmpty(model.Content))
        {
            return BadRequest("O campo 'content' é obrigatório.");
        }

        // Recuperar o post
        var post = await _context.Posts
            .Include(p => p.OriginalPost)
            .FirstOrDefaultAsync(p => p.Id == postId);

        if (post == null)
        {
            return NotFound("Post não encontrado.");
        }

        // Identificar o post-alvo para o comentário
        var targetPostId = post.OriginalPostId ?? post.Id;

        // Verificar se é uma partilha e validar amizade
        if (post.OriginalPostId.HasValue)
        {
            bool isFriend = await _context.UserFriendship
                .AnyAsync(uf =>
                    (uf.RequesterId == userId && uf.ReceiverId == post.IdUser && uf.IsConfirmed) ||
                    (uf.RequesterId == post.IdUser && uf.ReceiverId == userId && uf.IsConfirmed));

            if (!isFriend)
            {
                return Forbid("Apenas amigos podem comentar nesta publicação.");
            }
        }

        // Validar associação à comunidade se o post pertence a uma
        if (post.CommunityId.HasValue)
        {
            var member = await _context.UserCommunity
                .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == post.CommunityId && !uc.IsPending);

            if (member == null)
            {
                return BadRequest("O utilizador não é membro da comunidade ou ainda está pendente.");
            }
        }

        // Criar o comentário
        var comment = new Comment
        {
            PostId = targetPostId,
            UserId = userId,
            Content = model.Content,
            CreatedAt = DateTime.Now
        };

        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();

        await _notificationService.NotifyAuthorOfComment(targetPostId, userId, model.Content);

        return Ok("Comentário adicionado com sucesso.");
    }

    /// <summary>
    /// Retrieves comments on a specific post, checking user authentication and friendship status if the post is shared.
    /// </summary>
    /// <param name="postId">The unique identifier of the post for which comments are to be retrieved.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok with a list of comments if the post is found and the user is authorized to view them.
    /// - Unauthorized if the user is not authenticated.
    /// - NotFound if the specified post does not exist.
    /// </returns>
    [HttpGet("{postId}/comments")]
    public async Task<IActionResult> GetCommentsOnPost(int postId)
    {
        // Recupera o ID do utilizador autenticado
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null)
        {
            return Unauthorized("Utilizador não autenticado.");
        }
        int userId = int.Parse(userIdClaim.Value);

        // Recupera o post pelo ID
        var post = await _context.Posts
            .Include(p => p.OriginalPost)
            .FirstOrDefaultAsync(p => p.Id == postId);

        if (post == null)
        {
            return NotFound("Post não encontrado.");
        }

        // Verifica se o post é um share e usa o OriginalPostId
        var targetPostId = post.OriginalPostId ?? postId;

        // Verifica se o comentário pode ser feito no post original (amigos)
        if (post.OriginalPostId.HasValue)
        {
            bool isFriend = await _context.UserFriendship
                .AnyAsync(uf =>
                    (uf.RequesterId == userId && uf.ReceiverId == post.IdUser && uf.IsConfirmed) ||
                    (uf.RequesterId == post.IdUser && uf.ReceiverId == userId && uf.IsConfirmed));

            if (!isFriend)
            {
                return Forbid("Apenas amigos podem interagir com esta publicação.");
            }
        }

        // Recupera os comentários do post alvo
        var comments = await _context.Comments
            .Where(c => c.PostId == targetPostId)
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new
            {
                c.Id,
                c.PostId,
                c.UserId,
                Username = _context.Users
                    .Where(u => u.Id == c.UserId)
                    .Select(u => u.Nome)
                    .FirstOrDefault(),
                c.Content,
                c.CreatedAt
            })
            .ToListAsync();

        return Ok(comments);
    }

    /// <summary>
    /// Retrieves posts authored by a specific user, identified by their userId.
    /// </summary>
    /// <param name="userId">The unique identifier of the user whose posts are to be retrieved.</param>
    /// <returns>
    /// A task that represents the asynchronous operation. The task result contains an IActionResult that can be:
    /// - Ok with a list of post DTOs if the posts are successfully retrieved.
    /// - NotFound if the specified user does not exist.
    /// </returns>
    [HttpGet("user-posts/{userId}")]
    public async Task<IActionResult> GetPostsByUserId(int userId)
    {
        // Verifica se o usuário existe
        var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
        if (!userExists)
        {
            return NotFound("Usuário não encontrado.");
        }

        // Recupera os posts do usuário
        var userPosts = await _context.Posts
            .Where(p => p.IdUser == userId) // Filtra pelo ID do usuário
            .Include(p => p.User) // Inclui os dados do autor do post
            .Include(p => p.OriginalPost) // Inclui informações do post original, se for um repost
            .OrderByDescending(p => p.DataCriacao) // Ordena por data de criação (mais recente primeiro)
            .ToListAsync();

        // Mapeia os posts para o DTO
        var postDtos = userPosts.Select(post => new PostDto
        {
            PostId = post.Id,
            UserId = post.IdUser,
            Username = post.User.Nome,
            Content = post.Conteudo,
            OriginalPostId = post.OriginalPostId,
            OriginalUsername = post.OriginalPost?.User?.Nome,
            Isbn = post.Isbn,
            BookTitle = post.BookTitle,
            NumberOfReactions = _context.PostReactions.Count(r => r.PostId == post.Id),
            NumberOfComments = _context.Comments.Count(c => c.PostId == post.Id),
            CreatedAt = post.DataCriacao
        }).ToList();

        return Ok(postDtos);
    }
}
