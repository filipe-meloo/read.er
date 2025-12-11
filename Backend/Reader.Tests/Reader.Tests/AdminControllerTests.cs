using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes;
using Read.er.Models;
using Read.er.Models.Posts;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;
using Stripe;

public class AdminControllerTests : IDisposable
{
    private readonly AdminController _controller;
    private readonly AppDbContext _context;
    private readonly Mock<RefundService> _mockRefundService;

    public AdminControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);

        var stripeSettings = Options.Create(new StripeSettings
        {
            SecretKey = "sk_test_123"
        });

        _controller = new AdminController(_context, stripeSettings);

        _controller.ControllerContext.HttpContext = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(new Claim[]
            {
                new("role", "ADMIN")
            }))
        };

        _mockRefundService = new Mock<RefundService>();
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    private async Task<User> AddUser(int id, bool isActive, Role role)
    {
        var user = new User
        {
            Id = id,
            Nome = $"User{id}",
            Email = $"user{id}@example.com",
            Password = "password123",
            Username = $"user{id}",
            IsActive = isActive,
            Role = role,
            Bio = "Test bio"
        };
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
        return user;
    }

    private async Task<CompletedSaleTrade> AddCompletedSaleTrade(int originalSaleTradeId, int sellerId)
    {
        var sale = new CompletedSaleTrade
        {
            OriginalSaleTradeId = originalSaleTradeId,
            SellerId = sellerId,
            StripeTransaction = "pi_test_123",
            DateCompleted = DateTime.UtcNow,
            Isbn = "1234567890123"
        };
        await _context.CompletedSaleTrades.AddAsync(sale);
        await _context.SaveChangesAsync();
        return sale;
    }


    [Fact]
    public async Task RefundCompletedSale_ShouldReturnNotFound_WhenCompletedSaleDoesNotExist()
    {
        var result = await _controller.RefundCompletedSale(999);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task GetAllSaleTrades_ShouldReturnSaleTrades_WhenSaleTradesExist()
    {
        var saleTrade = new SaleTrade { Id = 1, IdUser = 1, Isbn = "12345", Price = 10.99m };
        _context.SaleTrades.Add(saleTrade);
        await _context.SaveChangesAsync();

        var result = await _controller.GetAllSaleTrades();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var sales = Assert.IsAssignableFrom<IEnumerable<SaleTrade>>(okResult.Value);
        Assert.Single(sales);
    }

    [Fact]
    public async Task GetAllCompletedSaleTrades_ShouldReturnCompletedSaleTrades_WhenTheyExist()
    {
        var completedSale = await AddCompletedSaleTrade(1, 1);

        var result = await _controller.GetAllCompletedSaleTrades();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var completedSales = Assert.IsAssignableFrom<IEnumerable<CompletedSaleTrade>>(okResult.Value);
        Assert.Single(completedSales);
    }

    [Fact]
    public async Task GetAllCompletedSaleTrades_ShouldReturnNotFound_WhenNoCompletedSaleTradesExist()
    {
        var result = await _controller.GetAllCompletedSaleTrades();

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }


    private async Task<Post> AddPost(int id, bool isReported, bool isInappropriate = false)
    {
        var post = new Post
        {
            Id = id,
            Conteudo = $"Post content {id}",
            Isbn = "1234567890",
            IsReported = isReported,
            IsInappropriate = isInappropriate,
            BookTitle = "Livro Teste"
        };
        await _context.Posts.AddAsync(post);
        await _context.SaveChangesAsync();
        return post;
    }

    [Fact]
    public async Task GetAllUsers_ShouldReturnAllUsers_WhenUsersExist()
    {
        await AddUser(1, true, Role.Leitor);
        await AddUser(2, false, Role.Autor);

        var result = await _controller.GetAllUsers();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var users = Assert.IsAssignableFrom<IEnumerable<User>>(okResult.Value);
        Assert.Equal(2, users.Count());
    }

    [Fact]
    public async Task GetAllUsers_ShouldReturnEmptyList_WhenNoUsersExist()
    {
        var result = await _controller.GetAllUsers();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var users = Assert.IsAssignableFrom<IEnumerable<User>>(okResult.Value);
        Assert.Empty(users);
    }

    [Fact]
    public async Task ToggleUserStatus_ShouldActivateUser_WhenUserIsInactive()
    {
        var user = await AddUser(1, false, Role.Leitor);

        var result = await _controller.ToggleUserStatus(user.Id);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var resultData = Assert.IsAssignableFrom<dynamic>(okResult.Value);
        Assert.Equal("Conta ativada com sucesso.", resultData.Message);
    }

    [Fact]
    public async Task ToggleUserStatus_ShouldReturnNotFound_WhenUserDoesNotExist()
    {
        var result = await _controller.ToggleUserStatus(999);

        Assert.IsType<NotFoundObjectResult>(result);
    }


    [Fact]
    public async Task GetReportedPosts_ShouldReturnReportedPosts_WhenPostsAreReported()
    {
        await AddPost(1, true);
        await AddPost(2, false);

        var result = await _controller.GetReportedPosts();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var posts = Assert.IsAssignableFrom<IEnumerable<Post>>(okResult.Value);
        Assert.Single(posts);
    }

    [Fact]
    public async Task GetReportedPosts_ShouldReturnEmptyList_WhenNoPostsAreReported()
    {
        await AddPost(1, false);
        await AddPost(2, false);

        var result = await _controller.GetReportedPosts();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var posts = Assert.IsAssignableFrom<IEnumerable<Post>>(okResult.Value);
        Assert.Empty(posts);
    }

    [Fact]
    public async Task DeletePost_ShouldDeletePost_WhenPostExists()
    {
        var post = await AddPost(1, true);


        var result = await _controller.DeletePost(post.Id);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var resultData = Assert.IsType<DeletePostDto>(okResult.Value);
        Assert.Equal("Publicação removida com sucesso.", resultData.Message);
    }

    [Fact]
    public async Task DeletePost_ShouldReturnNotFound_WhenPostDoesNotExist()
    {
        var result = await _controller.DeletePost(999);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task MarkPostAsInappropriate_ShouldMarkPost_WhenPostExists()
    {
        var post = await AddPost(1, true);

        var result = await _controller.MarkPostAsInappropriate(post.Id);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var resultData = Assert.IsType<MarkPostDto>(okResult.Value);

        Assert.Equal("Publicação marcada como impropria.", resultData.Message);
        Assert.Equal(post.Id, resultData.PostId);
    }

    [Fact]
    public async Task MarkPostAsInappropriate_ShouldReturnNotFound_WhenPostDoesNotExist()
    {
        var result = await _controller.MarkPostAsInappropriate(999);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        Assert.Equal("Publicação não encontrada.", notFoundResult.Value);
    }
}