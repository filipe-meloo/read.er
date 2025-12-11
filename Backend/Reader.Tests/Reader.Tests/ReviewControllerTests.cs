using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;

public class ReviewControllerTests
{
    private readonly AppDbContext _context;
    private readonly Mock<ITokenService> _mockTokenService;
    private readonly ReviewController _controller;

    public ReviewControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _mockTokenService = new Mock<ITokenService>();
        _controller = new ReviewController(_context, _mockTokenService.Object);
    }

    [Fact]
    public async Task RateBook_ShouldReturnOk_WhenReviewIsAdded()
    {
        // Arrange
        var isbn = "1234567890";
        var rating = 5;
        var comment = "Great book!";
        var userId = 1;

        _mockTokenService.Setup(s => s.GetUserIdByToken()).Returns(userId);

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
        await _context.SaveChangesAsync();
        
        // Act
        var bookReview = new BookReviewDto
        {
            Isbn = isbn,
            Rating = rating,
            Comment = comment
        };
        
        var result = await _controller.RateBook(bookReview);

        // Assert
        Assert.IsType<OkObjectResult>(result);
        Assert.Single(_context.BookReviews);
    }

    [Fact]
    public async Task RateBook_ShouldReturnBadRequest_WhenReviewAlreadyExists()
    {
        // Arrange
        var isbn = "1234567890";
        var userId = 1;
        _context.BookReviews.Add(new BookReview { UserId = userId, Isbn = isbn, Comment = "Existing review" });
        await _context.SaveChangesAsync();

        _mockTokenService.Setup(s => s.GetUserIdByToken()).Returns(userId);

        // Act
        var bookReview = new BookReviewDto
        {
            Isbn = isbn,
            Rating = 5,
            Comment = "Existing review"
        };
        
        var result = await _controller.RateBook(bookReview);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
    }
    
    [Fact]
    public async Task RateSaleTrade_ShouldReturnUnauthorized_WhenUserIsNotBuyer()
    {
        // Arrange
        var originalSaleTradeId = 1;
        var userId = 2;

        _context.SaleTradeOffers.Add(new SaleTradeOffer
        {
            IdOffer = originalSaleTradeId,
            IdUser = 1,
            SaleTrade = new SaleTrade { IdUser = 1 } // Para simular um trade offer
        });
        await _context.SaveChangesAsync();

        _mockTokenService.Setup(s => s.GetUserIdByToken()).Returns(userId);

        var rateTradeOfferDto = new ReviewController.RateTradeOfferDto
        {
            TradeOfferId = originalSaleTradeId,
            Rating = 4,
            Comment = "Good transaction."
        };

        // Act
        var result = await _controller.RateTradeOffer(rateTradeOfferDto);

        // Assert
        Assert.IsType<UnauthorizedObjectResult>(result);
    }
    
    [Fact]
    public async Task RateSaleTrade_ShouldReturnOk_WhenReviewIsAdded()
    {
        // Arrange
        var originalSaleTradeId = 1;
        var userId = 1;

        _context.SaleTradeOffers.Add(new SaleTradeOffer
        {
            IdOffer = originalSaleTradeId,
            IdUser = userId,
            SaleTrade = new SaleTrade { IdUser = 2 }
        });
        await _context.SaveChangesAsync();

        _mockTokenService.Setup(s => s.GetUserIdByToken()).Returns(userId);

        var rateTradeOfferDto = new ReviewController.RateTradeOfferDto
        {
            TradeOfferId = originalSaleTradeId,
            Rating = 5,
            Comment = "Excellent!"
        };

        // Act
        var result = await _controller.RateTradeOffer(rateTradeOfferDto);

        // Assert
        Assert.IsType<OkObjectResult>(result);
        Assert.Single(_context.SaleTradeReviews);
    }

}