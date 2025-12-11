using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs.Wishlist;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Book;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;

namespace Read.er.Tests;

public class WishlistControllerTests : IDisposable
{
    private readonly WishlistController _controller;
    private readonly AppDbContext _mockContext;
    private readonly Mock<IGoogleBooksService> _mockGoogleBooksService;
    private readonly Mock<ITokenService> _mockTokenService;

    public WishlistControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _mockContext = new AppDbContext(options);
        _mockGoogleBooksService = new Mock<IGoogleBooksService>();
        _mockTokenService = new Mock<ITokenService>();

        _controller = new WishlistController(_mockContext, _mockGoogleBooksService.Object, _mockTokenService.Object);
    }

    public void Dispose()
    {
        _mockContext.Database.EnsureDeleted();
        _mockContext.Dispose();
    }

    private void SetUserClaims(int userId)
    {
        var claims = new List<Claim>
        {
            new("userId", userId.ToString())
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var claimsPrincipal = new ClaimsPrincipal(identity);

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = claimsPrincipal }
        };

        // Configurar o mock para retornar o userId
        _mockTokenService.Setup(ts => ts.GetUserIdByToken()).Returns(userId);
    }

    private void SeedDatabase()
    {
        _mockContext.Users.AddRange(
            new User
            {
                Id = 1, Email = "user@example.com", Username = "user", Nome = "User Name", Password = "password",
                Role = Role.Leitor, Bio = "Test Bio"
            },
            new User
            {
                Id = 2, Email = "author@example.com", Username = "author", Nome = "Author Name", Password = "password",
                Role = Role.Autor, Bio = "Test Bio"
            },
            new User
            {
                Id = 3, Email = "friend@example.com", Username = "friend", Nome = "Friend Name", Password = "password",
                Role = Role.Leitor, Bio = "Test Bio"
            }
        );

        _mockContext.SaleTrades.Add(new SaleTrade
        {
            Id = 1,
            IdUser = 3,
            Isbn = "9780140449136",
            Price = 10.99M,
            State = BookState.Usado,
            Notes = "Descrição do Livro",
            IsAvailableForSale = true
        });

        _mockContext.UserFriendship.Add(new UserFriendship
        {
            RequesterId = 1,
            ReceiverId = 3,
            IsConfirmed = true
        });

        _mockContext.SaveChanges();
    }

    [Fact]
    public async Task AddToWishlist_ShouldReturnConflict_WhenItemAlreadyInWishlist()
    {
        SeedDatabase();

        SetUserClaims(1);
        var model = new AddToWishlistDto { SaleTradeId = 1 };
        _mockContext.Wishlists.Add(new Wishlist { UserId = 1, SaleTradeId = model.SaleTradeId });
        await _mockContext.SaveChangesAsync();

        var result = await _controller.AddToWishlist(model);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Equal("Já adicionou este item à Wishlist.", ((ConflictObjectResult)result).Value);
    }

    [Fact]
    public async Task AddToWishlist_ShouldReturnNotFound_WhenSaleTradeDoesNotExist()
    {
        SeedDatabase();
        SetUserClaims(1);

        var model = new AddToWishlistDto { SaleTradeId = 99 };

        var result = await _controller.AddToWishlist(model);

        Assert.IsType<NotFoundObjectResult>(result);
        Assert.Equal("Venda ou troca não encontrada.", ((NotFoundObjectResult)result).Value);
    }

    [Fact]
    public async Task AddToWishlist_ShouldReturnBadRequest_WhenAddingOwnSaleTrade()
    {
        SeedDatabase();
        SetUserClaims(3);

        var model = new AddToWishlistDto { SaleTradeId = 1 };

        var result = await _controller.AddToWishlist(model);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal("Não pode adicionar o seu próprio anúncio à Wishlist.", ((BadRequestObjectResult)result).Value);
    }

    [Fact]
    public async Task AddToWishlist_ShouldReturnUnauthorized_WhenSaleTradeOwnerIsNotFriend()
    {
        SeedDatabase();
        SetUserClaims(2);

        var model = new AddToWishlistDto { SaleTradeId = 1 };

        var result = await _controller.AddToWishlist(model);

        Assert.IsType<ForbidResult>(result);
    }


    [Fact]
    public async Task GetWishlist_ShouldReturnNotFound_WhenNoItemsInWishlist()
    {
        SetUserClaims(1);

        var result = await _controller.GetWishlist();

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task RemoveFromWishlist_ShouldRemoveItemSuccessfully()
    {
        SeedDatabase();
        SetUserClaims(1);

        var wishlistItem = new Wishlist { UserId = 1, SaleTradeId = 1 };
        _mockContext.Wishlists.Add(wishlistItem);
        await _mockContext.SaveChangesAsync();

        var model = new AddToWishlistDto { SaleTradeId = 1 };
        var result = await _controller.RemoveFromWishlist(model);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Venda removida da lista de desejos.", okResult.Value);

        var removedItem = await _mockContext.Wishlists.FirstOrDefaultAsync(w => w.UserId == 1 && w.SaleTradeId == 1);
        Assert.Null(removedItem);
    }

    [Fact]
    public async Task RemoveFromWishlist_ShouldReturnNotFound_WhenItemNotInWishlist()
    {
        SetUserClaims(1);

        var model = new AddToWishlistDto { SaleTradeId = 1 };
        var result = await _controller.RemoveFromWishlist(model);

        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);
        Assert.Equal("Venda não encontrada na lista de desejos.", notFoundResult.Value);
    }
}