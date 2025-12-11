using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes;
using Read.er.Enumeracoes.Post;
using Read.er.Interfaces;
using Read.er.Models;

namespace Read.er.Services;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    
    public NotificationService(AppDbContext context, IGoogleBooksService googleBooksService, WsManager wsManager)
    {
        _context = context;
        _googleBooksService = googleBooksService;
        _wsManager = wsManager;
    }
    
    
    public async Task<Notification> CreateNotificationAsync(CreateNotificationDto model)
    {
        var notification = new Notification
        {
            UserId = model.UserId,
            Type = model.Type,
            Title = model.Title,
            Content = model.Content,
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return notification;
    }
    
    public async Task NotifyFriendsOfNewPost(int userId, string content)
    {
        var friends = await _context.UserFriendship
            .Where(uf => (uf.RequesterId == userId || uf.ReceiverId == userId) && uf.IsConfirmed)
            .Select(uf => uf.RequesterId == userId ? uf.ReceiverId : uf.RequesterId)
            .ToListAsync();

        foreach (var friendId in friends)
        {
            var notification = new Notification
            {
                UserId = friendId,
                Type = NotificationType.NewPost,
                Title = "Novo post do seu amigo",
                Content =
                    $"{content.Substring(0, Math.Min(content.Length, 50))}...", // Exemplo: Limita o conteúdo a 50 caracteres
                DateCreated = DateTime.UtcNow,
                Read = false
            };

            await SendNotificationToUser(notification.UserId, notification);
            
            _context.Notifications.Add(notification);
        }

        await _context.SaveChangesAsync();
    }
    
    public async Task NotifyCommunityMembersOfNewPost(int communityId, int userId, string content)
    {
        var members = await _context.UserCommunity
            .Where(uc =>
                uc.CommunityId == communityId && !uc.IsPending && uc.UserId != userId) // Excluir o autor do post
            .Select(uc => uc.UserId)
            .ToListAsync();

        foreach (var memberId in members)
        {
            var notification = new Notification
            {
                UserId = memberId,
                Type = NotificationType.NewPost,
                Title = "Novo post na comunidade",
                Content =
                    $"{content.Substring(0, Math.Min(content.Length, 50))}...", // Exemplo: Limita o conteúdo a 50 caracteres
                DateCreated = DateTime.UtcNow,
                Read = false
            };
            
            await SendNotificationToUser(notification.UserId, notification);

            _context.Notifications.Add(notification);
        }

        await _context.SaveChangesAsync();
    }
    
    public async Task NotifyAuthorOfComment(int postId, int commenterId, string commentContent)
    {
        var post = await _context.Posts.FindAsync(postId);
        if (post == null) return;

        var commenter = await _context.Users.FindAsync(commenterId);
        if (commenter == null) return;

        var notification = new Notification
        {
            UserId = post.IdUser,
            Type = NotificationType.PostComment,
            Title = "Novo comentario no seu post",
            Content =
                $"{commenter.Nome} comentou: {commentContent.Substring(0, Math.Min(commentContent.Length, 50))}...",
            DateCreated = DateTime.UtcNow,
            Read = false
        };
        
        await SendNotificationToUser(notification.UserId, notification);

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    // Notificar o autor do post quando alguém reage
    public async Task NotifyAuthorOfReaction(int postId, int reactorId, ReactionType reactionType)
    {
        var post = await _context.Posts.FindAsync(postId);
        if (post == null) return;

        var reactor = await _context.Users.FindAsync(reactorId);
        if (reactor == null) return;

        var notification = new Notification
        {
            UserId = post.IdUser,
            Type = NotificationType.PostLike,
            Title = "Nova reacao no seu post",
            Content = $"{reactor.Nome} reagiu com {reactionType} ao seu post.",
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    //==================SALES AND TRADES=======================
    public async Task NotifyFriendsOfNewSale(int userId, string isbn, bool isAvailableForSale, bool isAvailableForTrade)
    {
        var user = await _context.Users.FindAsync(userId);
        var userName = user?.Nome ?? "O seu amigo";

        var friends = await _context.UserFriendship
            .Where(uf => (uf.RequesterId == userId || uf.ReceiverId == userId) && uf.IsConfirmed)
            .Select(uf => uf.RequesterId == userId ? uf.ReceiverId : uf.RequesterId)
            .ToListAsync();

        NotificationType notificationType;
        string title;
        string content;
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var btitle = bookDetails?.Title ?? "Título desconhecido";

        if (isAvailableForSale && isAvailableForTrade)
        {
            notificationType = NotificationType.MarketplaceNewSaleTradePosted;
            title = "Novo anúncio de venda e troca";
            content = $"{userName} postou um novo livro a venda e disponível para troca: {btitle}";
        }
        else if (isAvailableForSale)
        {
            notificationType = NotificationType.MarketplaceNewSalePosted;
            title = "Novo anúncio de venda";
            content = $"{userName} postou um novo livro a venda: {btitle}";
        }
        else // Apenas troca
        {
            notificationType = NotificationType.MarketplaceNewTradePosted;
            title = "Novo anúncio de troca";
            content = $"{userName} postou um novo livro disponivel para troca: {btitle}";
        }

        foreach (var friendId in friends)
        {
            var notification = new CreateNotificationDto
            {
                UserId = friendId,
                Type = notificationType,
                Title = title,
                Content = content
            };
            await CreateNotificationAsync(notification);
        }
    }


    // Método para notificar o vendedor sobre uma nova oferta
    public async Task NotifySellerOfNewOffer(int sellerId, string isbn, string buyerName)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Titulo desconhecido";
        var notification = new CreateNotificationDto
        {
            UserId = sellerId,
            Type = NotificationType.MarketplaceTradeoffer,
            Title = "Nova oferta recebida",
            Content = $"{buyerName} fez uma oferta para o seu livro: {title}"
        };
        
        await CreateNotificationAsync(notification);
    }

    // Método para notificar o comprador sobre a compra concluída com o título do livro
    public async Task NotifyBuyerOfPurchaseCompletion(int buyerId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = buyerId,
            Type = NotificationType.MarketplaceSaleCompleted,
            Title = "Compra Concluída",
            Content = $"A sua compra do livro '{title}' foi concluida com sucesso.", // Usar o título obtido
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    // Método para notificar o comprador sobre uma troca concluída com o título do livro
    public async Task NotifyBuyerOfTradeCompletion(int buyerId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = buyerId,
            Type = NotificationType.MarketplaceTradeAccepted,
            Title = "Troca Concluída",
            Content = $"A sua troca pelo livro '{title}' foi concluida com sucesso.", // Usar o título obtido
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    public async Task NotifySellerOfSaleCompletion(int sellerId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = sellerId,
            Type = NotificationType.MarketplaceSaleCompleted,
            Title = "Venda Concluída",
            Content = $"O seu livro '{title}' foi vendido com sucesso.",
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    // Método para notificar o vendedor sobre uma troca concluída com o título do livro
    public async Task NotifySellerOfTradeCompletion(int sellerId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = sellerId,
            Type = NotificationType.MarketplaceTradeAccepted,
            Title = "Troca Concluída",
            Content = $"A sua troca pelo livro '{title}' foi concluida com sucesso.", // Usar o título obtido
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    public async Task NotifyUserOfTradeRejection(int userId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";


        var notification = new Notification
        {
            UserId = userId,
            Type = NotificationType.MarketplaceTradeRejected,
            Title = "Troca Rejeitada",
            Content = $"A sua oferta de troca pelo livro '{title}' foi rejeitada.",
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }

    public async Task NotifyUserOfWishlistSaleCompletion(int userId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = userId,
            Type = NotificationType.MarketplaceSaleCompleted,
            Title = "Item Vendido",
            Content = $"O livro '{title}', que estava na sua wishlist, ja nao se encontra mais disponivel.",
            DateCreated = DateTime.UtcNow,
            Read = false
        };
        
        await SendNotificationToUser(notification.UserId, notification);

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }


    public async Task NotifyUserOfWishlistTradeCompletion(int userId, string isbn)
    {
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        var title = bookDetails?.Title ?? "Título desconhecido";

        var notification = new Notification
        {
            UserId = userId,
            Type = NotificationType.MarketplaceTradeAccepted,
            Title = "Item Trocado",
            Content = $"O livro '{title}', que estava na sua wishlist, foi trocado por outra pessoa.",
            DateCreated = DateTime.UtcNow,
            Read = false
        };

        await SendNotificationToUser(notification.UserId, notification);
        
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }
    
    private readonly WsManager _wsManager;

    public async Task SendNotificationToUser(int userId, Notification notification)
    {
        var notificationMessage = JsonSerializer.Serialize(new
        {
            notification.Id,
            notification.UserId,
            notification.Type,
            notification.Title,
            notification.Content,
            notification.DateCreated
        });

        await _wsManager.SendMessageToUser(userId, notificationMessage);
    }
}