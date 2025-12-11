using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Users;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Leitor")]
public class UserFriendshipController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITokenService _tokenService;
    private readonly INotificationService _notificationService;

    public UserFriendshipController(AppDbContext context, INotificationService notificationService,
        ITokenService tokenService)
    {
        _context = context;
        _notificationService = notificationService;
        _tokenService = tokenService;
    }

    /// <summary>
    /// Sends a friend request to the specified user.
    /// </summary>
    /// <param name="userId">The ID of the user to whom the friend request is being sent.</param>
    /// <returns>An IActionResult indicating the result of the operation. Returns "Pedido de Amizade enviado!" on success, or an error message if the operation fails.</returns>
    [HttpPost("SendFriendRequest/{userId}")]
    public async Task<IActionResult> SendFriendRequest(int userId)
    {
        var requester = _tokenService.GetUserIdByToken();


        var receiver = await _context.Users.FindAsync(userId);
        if (receiver == null) return NotFound("Utilizador não encontrado.");

        var existingRequest = await _context.UserFriendship
            .AnyAsync(uf => uf.RequesterId == requester && uf.ReceiverId == userId && !uf.IsConfirmed);
        if (existingRequest) return BadRequest("Já existe um pedido de amizade pendente.");

        var friendship = new UserFriendship
        {
            RequesterId = requester,
            ReceiverId = receiver.Id,
            IsConfirmed = false
        };

        _context.UserFriendship.Add(friendship);
        await _context.SaveChangesAsync();
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = receiver.Id,
            Type = NotificationType.FriendRequestReceived,
            Title = "Novo pedido de amizade",
            Content = "Recebeu um novo pedido de amizade."
        });

        return Ok("Pedido de Amizade enviado!");
    }

    /// <summary>
    /// Retrieves a list of all pending friend requests for the currently authenticated user.
    /// </summary>
    /// <returns>An IActionResult containing a list of pending friend requests or a message indicating that there are no pending requests.</returns>
    [HttpGet("GetFriendRequests")]
    public async Task<IActionResult> GetFriendRequests()
    {
        var userId = _tokenService.GetUserIdByToken();

        var pendingRequests = await _context.UserFriendship
            .Where(uf => uf.ReceiverId == userId && !uf.IsConfirmed)
            .Select(uf => new FriendRequestDto
            {
                RequesterId = uf.RequesterId,
                RequesterName = _context.Users.FirstOrDefault(u => u.Id == uf.RequesterId).Nome,
                RequesterUsername = _context.Users.FirstOrDefault(u => u.Id == uf.RequesterId).Username, // Inclua o username
                IsConfirmed = uf.IsConfirmed
            })
            .ToListAsync();

        if (!pendingRequests.Any()) return NotFound("Não há pedidos de amizade pendentes.");
        return Ok(pendingRequests);
    }

    /// <summary>
    /// Accepts a friend request from the specified user.
    /// </summary>
    /// <param name="requesterId">The ID of the user who sent the friend request.</param>
    /// <returns>An IActionResult indicating the result of the operation. Returns "Pedido de amizade aceito!" on success, or an error message if the request is not found.</returns>
    [HttpPost("AcceptFriendRequest/{requesterId}")]
    public async Task<IActionResult> AcceptFriendRequest(int requesterId)
    {
        var userId = _tokenService.GetUserIdByToken();

        var friendship = await _context.UserFriendship
            .FirstOrDefaultAsync(uf => uf.RequesterId == requesterId && uf.ReceiverId == userId && !uf.IsConfirmed);

        if (friendship == null) return NotFound("Pedido de amizade não encontrado.");

        friendship.IsConfirmed = true;

        await _context.SaveChangesAsync();
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = requesterId,
            Type = NotificationType.FriendRequestAccepted,
            Title = "Pedido de amizade aceite",
            Content = "O seu pedido de amizade foi aceite."
        });
        return Ok("Pedido de amizade aceito!");
    }

    /// <summary>
    /// Declines a friend request from the specified user.
    /// </summary>
    /// <param name="requesterId">The ID of the user who sent the friend request.</param>
    /// <returns>An IActionResult indicating the result of the operation. Returns "Pedido de amizade recusado!" if successful, or an error message if the request is not found.</returns>
    [HttpPost("DeclineFriendRequest/{requesterId}")]
    public async Task<IActionResult> DeclineFriendRequest(int requesterId)
    {
        var userId = _tokenService.GetUserIdByToken();


        var friendship = await _context.UserFriendship
            .FirstOrDefaultAsync(uf => uf.RequesterId == requesterId && uf.ReceiverId == userId && !uf.IsConfirmed);

        if (friendship == null) return NotFound("Pedido de amizade não encontrado.");

        _context.UserFriendship.Remove(friendship);
        await _context.SaveChangesAsync();
        await _notificationService.CreateNotificationAsync(new CreateNotificationDto
        {
            UserId = requesterId,
            Type = NotificationType.FriendRequestDeclined,
            Title = "Pedido de amizade recusado",
            Content = "O seu pedido de amizade foi recusado."
        });
        return Ok("Pedido de amizade recusado!");
    }

    /// <summary>
    /// Removes a friendship between the current user and the specified friend.
    /// </summary>
    /// <param name="friendId">The ID of the friend to be removed.</param>
    /// <returns>An IActionResult indicating the result of the operation. Returns "Amizade removida com sucesso!" on success, or an error message if the friendship is not found.</returns>
    [HttpDelete("RemoveFriend/{friendId}")]
    public async Task<IActionResult> RemoveFriend(int friendId)
    {
        var userId = _tokenService.GetUserIdByToken();

        var friendship = await _context.UserFriendship
            .FirstOrDefaultAsync(uf => (uf.RequesterId == userId && uf.ReceiverId == friendId) ||
                                       (uf.RequesterId == friendId && uf.ReceiverId == userId));

        if (friendship == null) return NotFound("Amizade não encontrada.");

        _context.UserFriendship.Remove(friendship);
        await _context.SaveChangesAsync();

        return Ok("Amizade removida com sucesso!");
    }

    /// <summary>
    /// Searches for users with a role of "Leitor" whose username or name contains the specified query.
    /// </summary>
    /// <param name="query">The search string used to match against usernames and names.</param>
    /// <returns>An IActionResult containing a list of matching users or a not found response if no users match the query.</returns>
    [HttpGet("SearchUsers/{query}")]
    public async Task<IActionResult> SearchUsers(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return BadRequest("A consulta de pesquisa não pode estar vazia.");
        }

        var userId = _tokenService.GetUserIdByToken();

        // Ajuste para incluir apenas usuários do tipo "Leitor"
        var users = await _context.Users
            .Where(u => u.Id != userId &&
                        u.Role == Role.Leitor && // Filtra apenas leitores
                        (u.Username.Contains(query) || u.Nome.Contains(query)))
            .Select(u => new
            {
                u.Id,
                u.Username,
                u.Nome
            })
            .ToListAsync();

        if (!users.Any())
        {
            return NotFound("Nenhum user do tipo leitor encontrado para a pesquisa.");
        }

        return Ok(users);
    }

    /// <summary>
    /// Retrieves the list of friends for the current user.
    /// </summary>
    /// <returns>An IActionResult containing the list of friends, or a message indicating no friends exist.</returns>
    [HttpGet("GetFriends")]
    public async Task<IActionResult> GetFriends()
    {
        var userId = _tokenService.GetUserIdByToken();

        var friends = await _context.UserFriendship
            .Where(uf => uf.IsConfirmed && (uf.RequesterId == userId || uf.ReceiverId == userId))
            .Select(uf => new
            {
                FriendId = uf.RequesterId == userId ? uf.ReceiverId : uf.RequesterId,
                FriendName = uf.RequesterId == userId
                    ? _context.Users.FirstOrDefault(u => u.Id == uf.ReceiverId).Nome
                    : _context.Users.FirstOrDefault(u => u.Id == uf.RequesterId).Nome
            })
            .ToListAsync();

        if (!friends.Any()) return Ok("Você não tem amigos.");

        return Ok(friends);
    }
   
}