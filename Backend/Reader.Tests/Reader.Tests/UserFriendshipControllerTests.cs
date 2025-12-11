using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Users;
using Read.er.Services;

namespace Reader.Tests.Reader.Tests;

public class UserFriendshipControllerTests : IDisposable
{
    private readonly UserFriendshipController _controller;
    private readonly AppDbContext _context;
    private readonly Mock<ITokenService> _mockTokenService;
    private readonly Mock<WsManager> _mockWsManager;

    private readonly NotificationService _notificationService;
    private readonly IGoogleBooksService _googleBooksService;


    public UserFriendshipControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);

        _mockTokenService = new Mock<ITokenService>();
        _mockWsManager = new Mock<WsManager>(new HttpClient());

        _notificationService = new NotificationService(_context, _googleBooksService, _mockWsManager.Object);
        _controller = new UserFriendshipController(_context, _notificationService, _mockTokenService.Object);

        _controller.ControllerContext.HttpContext = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(new Claim[]
            {
                new("userId", "1")
            }))
        };
    }

    private void SetUserClaims(int userId)
    {
        var claims = new List<Claim> { new("userId", userId.ToString()) };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var claimsPrincipal = new ClaimsPrincipal(identity);

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claimsPrincipal }
        };

        _mockTokenService.Setup(ts => ts.GetUserIdByToken()).Returns(userId);
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    private async Task AddLeitorUser(int userId, string username)
    {
        await _context.Users.AddAsync(new User
        {
            Id = userId,
            Nome = username,
            Email = $"{username.ToLower()}@example.com",
            Password = "password123",
            Username = username,
            Role = Role.Leitor,
            Bio = "Test Bio"
        });
        await _context.SaveChangesAsync();
    }

    [Fact]
    public async Task SendFriendRequest_ShouldReturnOk_WhenUserIsLeitor()
    {
        // Arrange
        SetUserClaims(1);
        await AddLeitorUser(1, "LeitorUser1");
        await AddLeitorUser(2, "LeitorUser2");

        // Act
        var result = await _controller.SendFriendRequest(2);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Pedido de Amizade enviado!", okResult.Value);
    }

    // Teste para GetFriendRequests - Retornar pedidos pendentes para um LEITOR
    [Fact]
    public async Task GetFriendRequests_ShouldReturnPendingRequests_WhenUserIsLeitor()
    {
        // Arrange
        SetUserClaims(2);
        await AddLeitorUser(2, "LeitorUser");
        var requester = new User
        {
            Id = 1,
            Nome = "Test User",
            Email = "testuser@example.com",
            Password = "password123",
            Username = "testuser",
            Role = Role.Leitor,
            Bio = "Test Bio"
        };
        await _context.Users.AddAsync(requester);
        await _context.UserFriendship.AddAsync(new UserFriendship
        {
            RequesterId = requester.Id,
            ReceiverId = 2,
            IsConfirmed = false
        });
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetFriendRequests();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var pendingRequests = Assert.IsAssignableFrom<IEnumerable<FriendRequestDto>>(okResult.Value);
        Assert.Single(pendingRequests);

        // Verificar os valores das propriedades do pedido pendente
        var request = pendingRequests.First();
        Assert.Equal(requester.Id, request.RequesterId);
        Assert.Equal(requester.Nome, request.RequesterName);
        Assert.False(request.IsConfirmed);
    }

    // Teste para aceitar pedido de amizade válido
    [Fact]
    public async Task AcceptFriendRequest_ShouldReturnOk_WhenRequestIsAccepted()
    {
        // Arrange
        SetUserClaims(2);
        await AddLeitorUser(2, "ReceiverUser");
        var requester = new User
        {
            Id = 1,
            Nome = "Requester User",
            Email = "requester@example.com",
            Password = "password123",
            Username = "requesteruser",
            Role = Role.Leitor,
            Bio = "Test Bio"
        };
        await _context.Users.AddAsync(requester);
        await _context.UserFriendship.AddAsync(new UserFriendship
        {
            RequesterId = requester.Id,
            ReceiverId = 2,
            IsConfirmed = false
        });
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.AcceptFriendRequest(requester.Id);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Pedido de amizade aceito!", okResult.Value);
    }

    // Teste para recusar pedido de amizade
    [Fact]
    public async Task DeclineFriendRequest_ShouldReturnOk_WhenRequestIsDeclined()
    {
        // Arrange
        SetUserClaims(2);
        await AddLeitorUser(2, "ReceiverUser");
        var requester = new User
        {
            Id = 1,
            Nome = "Test User",
            Email = "testuser@example.com",
            Password = "password123",
            Username = "testuser",
            Role = Role.Leitor,
            Bio = "Test bio"
        };
        await _context.Users.AddAsync(requester);
        await _context.UserFriendship.AddAsync(new UserFriendship
        {
            RequesterId = requester.Id,
            ReceiverId = 2,
            IsConfirmed = false
        });
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.DeclineFriendRequest(requester.Id);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Pedido de amizade recusado!", okResult.Value);
    }

    // Teste para remover um amigo existente
    [Fact]
    public async Task RemoveFriend_ShouldReturnOk_WhenFriendIsRemoved()
    {
        // Arrange
        SetUserClaims(1);
        await AddLeitorUser(1, "RequesterUser");
        var friend = new User
        {
            Id = 2,
            Nome = "Friend User",
            Email = "friend@example.com",
            Password = "password123",
            Username = "frienduser",
            Role = Role.Leitor,
            Bio = "Test Bio"
        };
        await _context.Users.AddAsync(friend);
        await _context.UserFriendship.AddAsync(new UserFriendship
        {
            RequesterId = 1,
            ReceiverId = 2,
            IsConfirmed = true
        });
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.RemoveFriend(friend.Id);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Amizade removida com sucesso!", okResult.Value);
    }

    // Teste para GetFriends - Nenhum amigo existente
    [Fact]
    public async Task GetFriends_ShouldReturnMessage_WhenNoFriendsExist()
    {
        // Arrange
        SetUserClaims(1);
        await AddLeitorUser(1, "LeitorUser");

        // Act
        var result = await _controller.GetFriends();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Você não tem amigos.", okResult.Value);
    }
}