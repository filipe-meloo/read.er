using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Models;
using Read.er.Models.Communities;
using Read.er.Models.Posts;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;
using Stripe;

namespace Read.er.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly StripeSettings _stripeSettings;

    public AdminController(AppDbContext context, IOptions<StripeSettings> stripeSettings)
    {
        _context = context;
        _stripeSettings = stripeSettings.Value;
        StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
    }

    /// <summary>
    /// Retrieves all users from the database.
    /// </summary>
    /// <returns>
    /// An <see cref="ActionResult"/> containing an <see cref="IEnumerable{T}"/> of <see cref="User"/> objects,
    /// representing the collection of all users.
    /// </returns>
    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<User>>> GetAllUsers()
    {
        var users = await _context.Users.ToListAsync();
        return Ok(users);
    }

    /// <summary>
    /// Toggles the active status of a user.
    /// </summary>
    /// <param name="id">The unique identifier of the user whose status is to be toggled.</param>
    /// <returns>An <see cref="IActionResult"/> containing a <see cref="ToggleDto"/> with a success message and updated status, or a NotFound result if the user is not found.</returns>
    [HttpPatch("users/{id}/toggle-status")]
    public async Task<IActionResult> ToggleUserStatus(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound("Utilizador não encontrado.");

        user.IsActive = !user.IsActive;
        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        return Ok(new ToggleDto
        {
            Message = user.IsActive ? "Conta ativada com sucesso." : "Conta desativada com sucesso.",
            UserId = user.Id,
            IsActive = user.IsActive
        });
    }

    /// <summary>
    /// Retrieves reported posts from the database.
    /// </summary>
    /// <returns>
    /// An <see cref="ActionResult"/> containing an <see cref="IEnumerable{T}"/> of <see cref="Post"/> objects,
    /// representing the collection of reported posts.
    /// </returns>
    [HttpGet("posts/reported")]
    public async Task<ActionResult<IEnumerable<Post>>> GetReportedPosts()
    {
        var reportedPosts = await _context.Posts
            .Where(p => p.IsReported) // Considerando que exista um campo IsReported em Post
            .ToListAsync();

        return Ok(reportedPosts);
    }

    /// <summary>
    /// Deletes a specified post by its identifier.
    /// </summary>
    /// <param name="id">The identifier of the post to be deleted.</param>
    /// <returns>An <see cref="IActionResult"/> that is an <see cref="OkObjectResult"/> if the post is successfully deleted, or a <see cref="NotFoundObjectResult"/> if the post does not exist.</returns>
    [HttpDelete("posts/{id}")]
    public async Task<IActionResult> DeletePost(int id)
    {
        var post = await _context.Posts.FindAsync(id);
        if (post == null) return NotFound("Publicação não encontrada.");

        _context.Posts.Remove(post);
        await _context.SaveChangesAsync();

        return Ok(new DeletePostDto
        {
            Message = "Publicação removida com sucesso.",
            PostId = post.Id
        });
    }

    /// <summary>
    /// Marks a post as inappropriate based on the provided post identifier.
    /// </summary>
    /// <param name="id">The unique identifier of the post to be marked as inappropriate.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> indicating the outcome of the operation,
    /// where a successful mark returns a <see cref="OkObjectResult"/> with a <see cref="MarkPostDto"/>
    /// detailing the updated post status, and a not found status returns a <see cref="NotFoundObjectResult"/>
    /// if the post does not exist.
    /// </returns>
    [HttpPatch("posts/{id}/mark-inappropriate")]
    public async Task<IActionResult> MarkPostAsInappropriate(int id)
    {
        var post = await _context.Posts.FindAsync(id);
        if (post == null) return NotFound("Publicação não encontrada.");

        post.IsInappropriate = true;
        _context.Posts.Update(post);
        await _context.SaveChangesAsync();

        return Ok(new MarkPostDto
        {
            Message = "Publicação marcada como impropria.",
            PostId = post.Id
        });
    }

    /// <summary>
    /// Retrieves all sale trades from the database.
    /// </summary>
    /// <returns>
    /// An <see cref="ActionResult"/> containing an <see cref="IEnumerable{T}"/> of <see cref="SaleTrade"/> objects,
    /// representing the collection of all sale trades.
    /// </returns>
    [HttpGet("saletrades")]
    public async Task<ActionResult<IEnumerable<SaleTrade>>> GetAllSaleTrades()
    {
        var saleTrades = await _context.SaleTrades.ToListAsync();
        return Ok(saleTrades);
    }

    /// <summary>
    /// Retrieves all completed sale trades from the database.
    /// </summary>
    /// <returns>
    /// An <see cref="ActionResult"/> containing an <see cref="IEnumerable{T}"/> of <see cref="CompletedSaleTrade"/> objects,
    /// representing the collection of all completed sale trades.
    /// </returns>
    [HttpGet("completed-sales")]
    public async Task<ActionResult<IEnumerable<CompletedSaleTrade>>> GetAllCompletedSaleTrades()
    {
        var completedSaleTrades = await _context.CompletedSaleTrades.ToListAsync();
        if (completedSaleTrades == null || !completedSaleTrades.Any())
            return NotFound("Nenhuma venda completa encontrada.");

        return Ok(completedSaleTrades);
    }

    /// <summary>
    /// Deletes a completed sale trade from the database.
    /// </summary>
    /// <param name="id">The identifier of the completed sale trade to be deleted.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> indicating the outcome of the delete operation.
    /// If successful, it returns an HTTP 200 OK response with a confirmation message.
    /// If the completed sale trade is not found, it returns an HTTP 404 Not Found response.
    /// </returns>
    [HttpDelete("completed-sales/{id}")]
    public async Task<IActionResult> DeleteCompletedSaleTrade(int id)
    {
        var completedSaleTrade = await _context.CompletedSaleTrades.FindAsync(id);
        if (completedSaleTrade == null) return NotFound("Venda completa não encontrada.");

        _context.CompletedSaleTrades.Remove(completedSaleTrade);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Venda completa eliminada com sucesso." });
    }

    /// <summary>
    /// Processes a refund for a completed sale and restores the original sale trade.
    /// </summary>
    /// <param name="originalSaleTradeId">The identifier of the original sale trade associated with the completed sale to be refunded.</param>
    /// <returns>An <see cref="IActionResult"/> indicating the outcome of the refund process,
    /// which can be a successful refund and restoration of the sale, or an error message if the refund fails.</returns>
    [HttpPost("refund-sale/original/{originalSaleTradeId}")]
    public async Task<IActionResult> RefundCompletedSale(int originalSaleTradeId)
    {
        var completedSale = await _context.CompletedSaleTrades
            .FirstOrDefaultAsync(cs => cs.OriginalSaleTradeId == originalSaleTradeId);

        if (completedSale == null) return NotFound("Venda concluída não encontrada.");

        try
        {
            var options = new RefundCreateOptions
            {
                PaymentIntent = completedSale.StripeTransaction
            };
            var service = new RefundService();
            var refund = service.Create(options);

            var saleTrade = new SaleTrade
            {
                Id = completedSale.OriginalSaleTradeId,
                IdUser = completedSale.SellerId,
                Isbn = completedSale.Isbn,
                Price = completedSale.Price,
                IsAvailableForTrade = false,
                IsAvailableForSale = true,
                DateCreation = completedSale.DateCompleted
            };

            _context.SaleTrades.Add(saleTrade);
            _context.CompletedSaleTrades.Remove(completedSale);

            await _context.SaveChangesAsync();

            return Ok("Reembolso realizado e venda restaurada.");
        }
        catch (StripeException e)
        {
            return BadRequest(new { error = e.Message });
        }
    }

    /// <summary>
    /// Retrieves all communities from the database.
    /// </summary>
    /// <returns>
    /// An <see cref="ActionResult"/> containing an <see cref="IEnumerable{T}"/> of <see cref="Community"/> objects,
    /// representing the collection of all communities.
    /// </returns>
    [HttpGet("communities")]
    public async Task<ActionResult<IEnumerable<Community>>> GetAllCommunities()
    {
        var communities = await _context.Communities.ToListAsync();
        return Ok(communities);
    }

    /// <summary>
    /// Processes a report decision for a specific post based on the given parameters.
    /// </summary>
    /// <param name="postId">The identifier of the post to manage.</param>
    /// <param name="remove">Indicates whether the post should be removed or marked as solved and not inappropriate.</param>
    /// <returns>An <see cref="IActionResult"/> representing the outcome of the operation, including a message indicating whether the post was removed or marked as resolved.</returns>
    [HttpPost("{postId}/decision-report")]
    public async Task<IActionResult> SolveReport(int postId, [FromQuery] bool remove)
    {
        var post = await _context.Posts.FindAsync(postId);
        if (post == null)
            return NotFound("Publicação não encontrada.");

        if (remove)
        {
            _context.Posts.Remove(post);
        }
        else
        {
            post.IsReported = false;
            post.IsInappropriate = false;
            post.Solved = true;
            
            _context.Posts.Update(post);
        }

        await _context.SaveChangesAsync();
        return Ok(new
        {
            Message = remove ? "Post removido." : "Post não removido.",
            PostId = post.Conteudo
        });
    }
}