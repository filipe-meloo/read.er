using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs.Sales;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;

public class STControllerTests
{
    private readonly SaleTradeController _controller;
    private readonly AppDbContext _context;
    private readonly Mock<IGoogleBooksService> _mockBookService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly Mock<ITokenService> _mockTokenService;


    public STControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase("TestDatabase")
            .Options;

        _context = new AppDbContext(options);
        _mockBookService = new Mock<IGoogleBooksService>();
        _mockNotificationService = new Mock<INotificationService>();
        _mockTokenService = new Mock<ITokenService>();

        _controller = new SaleTradeController(_context, _mockBookService.Object, _mockNotificationService.Object,
            _mockTokenService.Object);
    }


    [Fact]
    public async Task CreateSaleTrade_ShouldReturnBadRequest_WhenUserIsNotAuthenticated()
    {
        // Arrange
        var model = new CreateSaleTradeDto();
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity())
            }
        };

        // Act
        var result = await _controller.CreateSaleTrade(model);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
        Dispose();
    }

    [Fact]
    public async Task CreateSaleTrade_ShouldReturnBadRequest_WhenBothSaleAndTradeAreFalse()
    {
        // Arrange
        var model = new CreateSaleTradeDto
        {
            IsAvailableForSale = false,
            IsAvailableForTrade = false
        };
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "1") }))
            }
        };

        // Act
        var result = await _controller.CreateSaleTrade(model);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
        Dispose();
    }

    [Fact]
    public async Task EditSaleTrade_ShouldReturnNotFound_WhenSaleTradeDoesNotExist()
    {
        // Arrange
        var model = new CreateSaleTradeDto();
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "1") }))
            }
        };

        // Act
        var result = await _controller.EditSaleTrade(1, model);

        // Assert
        Assert.IsType<NotFoundObjectResult>(result);
        Dispose();
    }

    [Fact]
    public async Task DeleteSaleTrade_ShouldReturnUnauthorized_WhenUserIsNotOwner()
    {
        // Arrange

        var user = new User
        {
            Id = 1,
            Username = "testuser",
            Email = "test@example.com",
            Nome = "Test User",
            Nascimento = new DateOnly(1990, 1, 1),
            Password = "hashed_password123",
            Bio = "Test Bio"
        };
        _context.Users.Add(user);
        _mockTokenService.Setup(s => s.GetUserIdByToken()).Returns(user.Id);
        await _context.SaveChangesAsync();
        
        var saleTrade = new SaleTrade
        {
            IdUser = 2,
            Isbn = "1234567890"
        };
        await _context.SaleTrades.AddAsync(saleTrade);
        await _context.SaveChangesAsync();

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "1") }))
            }
        };
        
        
        // Act
        var result = await _controller.DeleteSaleTrade(saleTrade.Id);

        // Assert
        Assert.IsType<ForbidResult>(result);
        Dispose();
    }
    
    [Fact]
    public async Task GetFriendsSaleTrades_ShouldReturnOk_WithEmptyList_WhenNoFriends()
    {
        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "1") }))
            }
        };

        var result = await _controller.GetFriendsSaleTrades();

        var okResult = Assert.IsType<ActionResult<IEnumerable<object>>>(result);
        Assert.NotNull(okResult.Result);

        var objectResult = Assert.IsType<OkObjectResult>(okResult.Result);
        var saleTrades = Assert.IsType<List<object>>(objectResult.Value);
        Assert.Empty(saleTrades);
        Dispose();
    }
    
    [Fact]
    public async Task DecideSaleTradeOffer_ShouldReturnBadRequest_WhenOfferIsAlreadyDeclined()
    {
        // Arrange
        var saleTrade = new SaleTrade
        {
            Id = 1,
            IdUser = 1, // ID do usuário
            Isbn = "1234567890",
            IsAvailableForTrade = true
        };

        await _context.SaleTrades.AddAsync(saleTrade);
        await _context.SaveChangesAsync();

        var saleTradeOffer = new SaleTradeOffer
        {
            Declined = true,
            IdSaleTrade = saleTrade.Id,
            IsbnOfferedBook = "1234567890",
            Message = "Sample message"
        };
        await _context.SaleTradeOffers.AddAsync(saleTradeOffer);
        await _context.SaveChangesAsync();

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "1") }))
            }
        };

        // Act
        var result = await _controller.DecideSaleTradeOffer(1, new SaleTradeOfferDecisionDto { Accept = true });

        // Assert
        Assert.IsType<ForbidResult>(result);
        Dispose();
    }


    [Fact]
    public async Task CreateSaleTradeOffer_ShouldReturnNotFound_WhenNotAvailableForTrade()
    {
        // Arrange
        var saleTrade = new SaleTrade { Isbn = "12345908651", IsAvailableForTrade = false };
        await _context.SaleTrades.AddAsync(saleTrade);
        await _context.SaveChangesAsync();

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("userId", "2") }))
            }
        };

        // Act
        var result = await _controller.CreateSaleTradeOffer(1, new CreateSaleTradeOfferDto());

        // Assert
        Assert.IsType<NotFoundObjectResult>(result);
        Dispose();
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }
}