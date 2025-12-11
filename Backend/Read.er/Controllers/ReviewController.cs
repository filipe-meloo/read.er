using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Models.SaleTrades;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Leitor")]
public class ReviewController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITokenService _tokenService;

    public ReviewController(AppDbContext context, ITokenService tokenService)
    {
        _context = context;
        _tokenService = tokenService;
    }

    /// <summary>
    /// Rates a book by adding a user review to the system.
    /// </summary>
    /// <param name="reviewDto">The DTO containing the book's ISBN, the rating value, and any optional comments.</param>
    /// <returns>Returns an <see cref="IActionResult"/> indicating the result of the operation.</returns>
    [HttpPost("rateBook")]
    public async Task<IActionResult> RateBook([FromBody] BookReviewDto reviewDto)
    {
        if (reviewDto.Rating < 1 || reviewDto.Rating > 5)
            return BadRequest("A avaliação deve ser entre 1 e 5.");

        var userId = _tokenService.GetUserIdByToken();
        if (userId == 0)
            return Unauthorized("Usuário não autenticado.");

        var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
        if (!userExists)
            return BadRequest("Usuário não encontrado.");

        var existingReview = await _context.BookReviews
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Isbn == reviewDto.Isbn);

        if (existingReview != null)
            return BadRequest("Já avaliou este livro.");

        var review = new BookReview
        {
            UserId = userId,
            Isbn = reviewDto.Isbn,
            Rating = reviewDto.Rating,
            Comment = reviewDto.Comment
        };

        _context.BookReviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok("Avaliação adicionada com sucesso.");
    }

    /// <summary>
    /// Calculates and returns the average rating for a specified book identified by its ISBN.
    /// </summary>
    /// <param name="isbn">The ISBN of the book for which the average rating is to be computed.</param>
    /// <returns>Returns an <see cref="IActionResult"/> containing the ISBN and the calculated average rating of the book. If there are no ratings, the average is returned as zero.</returns>
    [HttpGet("bookRatingAverage")]
    public async Task<IActionResult> GetBookRatingAverage(string isbn)
    {
        var ratings = await _context.BookReviews
            .Where(r => r.Isbn == isbn)
            .Select(r => r.Rating)
            .ToListAsync();

        var average = ratings.Any() ? Math.Round(ratings.Average(), 1) : 0.0;
        return Ok(new { ISBN = isbn, AverageRating = average });
    }

    /// <summary>
    /// Rates a trade offer by allowing a user to submit a review with a specified rating and comment.
    /// </summary>
    /// <param name="rateTradeOfferDto">The DTO containing the trade offer's ID, the rating value, and any optional comments.</param>
    /// <returns>Returns an <see cref="IActionResult"/> indicating the result of the operation, such as success, bad request, unauthorized, or not found.</returns>
    [Authorize]
    [HttpPost("rateTradeOffer")]
    public async Task<IActionResult> RateTradeOffer([FromBody] RateTradeOfferDto rateTradeOfferDto)
    {
        if (rateTradeOfferDto.Rating < 1 || rateTradeOfferDto.Rating > 5)
            return BadRequest("A avaliação deve ser entre 1 e 5.");

        var userId = _tokenService.GetUserIdByToken();

        var tradeOffer = await _context.SaleTradeOffers
            .Include(to => to.SaleTrade)
            .FirstOrDefaultAsync(to => to.IdOffer == rateTradeOfferDto.TradeOfferId);

        if (tradeOffer == null)
            return NotFound("Trade Offer não encontrada.");

        if (tradeOffer.IdUser != userId && tradeOffer.SaleTrade.IdUser != userId)
            return Unauthorized("Apenas participantes da troca podem avaliá-la.");

        var existingReview = await _context.SaleTradeReviews
            .FirstOrDefaultAsync(r => r.ReviewerId == userId && r.TradeOfferId == rateTradeOfferDto.TradeOfferId);

        if (existingReview != null)
            return BadRequest("Já avaliou esta Trade Offer.");

        var review = new SaleTradeReview
        {
            ReviewerId = userId,
            TradeOfferId = rateTradeOfferDto.TradeOfferId,
            Rating = rateTradeOfferDto.Rating,
            Comment = rateTradeOfferDto.Comment,
            DateReviewed = DateTime.UtcNow,
            SellerId = tradeOffer.SaleTrade.IdUser
        };

        _context.SaleTradeReviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok("Avaliação da Trade Offer adicionada com sucesso.");
    }

    /// <summary>
    /// Retrieves a trade offer along with its associated review based on the provided trade offer ID.
    /// </summary>
    /// <param name="tradeOfferId">The unique identifier of the trade offer to retrieve.</param>
    /// <returns>Returns an <see cref="IActionResult"/> containing the trade offer review details if found; otherwise, returns a NotFound result.</returns>
    [HttpGet("tradeOfferWithReview/{tradeOfferId}")]
    public async Task<IActionResult> GetTradeOfferWithReview(int tradeOfferId)
    {
        var userId = _tokenService.GetUserIdByToken();
        var tradeOffer = await _context.SaleTradeOffers
            .Include(to => to.SaleTrade)
            .FirstOrDefaultAsync(to => to.IdOffer == tradeOfferId);

        if (tradeOffer == null)
            return NotFound("Trade Offer não encontrada.");

        var review = await _context.SaleTradeReviews
            .FirstOrDefaultAsync(r => r.TradeOfferId == tradeOfferId);

        return Ok(new
        {
            Review = review 
        });
    }

    /// <summary>
    /// Calculates the average marketplace rating for a specified user based on their reviews.
    /// </summary>
    /// <param name="userId">The unique identifier of the user whose rating average is to be retrieved.</param>
    /// <returns>Returns an <see cref="IActionResult"/> containing the user ID and their average rating, or a zero average if no ratings exist.</returns>
    [HttpGet("userMarketplaceRatingAverage")]
    public async Task<IActionResult> GetUserMarketplaceRatingAverage(int userId)
    {
        var ratings = await _context.SaleTradeReviews
            .Where(r => r.ReviewerId == userId)
            .Select(r => r.Rating)
            .ToListAsync();

        var average = ratings.Any() ? Math.Round(ratings.Average(), 1) : 0.0;
        return Ok(new { UserId = userId, AverageRating = average });
    }
    
    public class RateTradeOfferDto
    {
        public int TradeOfferId { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; }
    }

}