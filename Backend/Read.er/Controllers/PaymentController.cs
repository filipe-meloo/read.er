using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Read.er.Data;
using Read.er.DTOs.Sales;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.SaleTrades;
using Stripe;
using Stripe.Checkout;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentController : ControllerBase
{
    private readonly StripeSettings _stripeSettings;
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly INotificationService _notificationService;
    
    public PaymentController(IOptions<StripeSettings> stripeSettings, AppDbContext context,
        IGoogleBooksService googleBooksService, INotificationService notificationService)
    {
        _stripeSettings = stripeSettings.Value;
        _context = context;
        _googleBooksService = googleBooksService;
        StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
        _notificationService = notificationService;
    }

    /// <summary>
    /// Creates a checkout session for purchasing a book based on the provided sale offer details.
    /// </summary>
    /// <param name="model">The sale offer information containing the ID of the sale trade.</param>
    /// <returns>An <see cref="IActionResult"/> containing the result of the operation. Returns the session details for a successful creation, or an error message if the operation fails.</returns>
    [HttpPost("create-checkout-session")]
    public async Task<IActionResult> CreateCheckoutSession([FromBody] SaleOfferDto model)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Não foi possível identificar o utilizador.");
        var currentUserId = int.Parse(userIdClaim.Value);


        var saleTrade = await _context.SaleTrades.FirstOrDefaultAsync(st => st.Id == model.SaleTradeId);
        if (saleTrade == null) return NotFound("Venda/Troca não encontrada.");

        if (saleTrade.IdUser == currentUserId) return BadRequest("Não pode comprar ou trocar o seu próprio item.");

        if (!saleTrade.IsAvailableForSale) return BadRequest("Este livro apenas foi disponibilizado para troca.");

        var isFriend = await _context.UserFriendship
            .AnyAsync(uf =>
                uf.IsConfirmed &&
                ((uf.RequesterId == currentUserId && uf.ReceiverId == saleTrade.IdUser) ||
                 (uf.RequesterId == saleTrade.IdUser && uf.ReceiverId == currentUserId))
            );
        if (!isFriend) return Unauthorized("Apenas amigos podem comprar ou trocar itens uns dos outros.");

        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(saleTrade.Isbn);
        if (bookDetails == null) return NotFound("Livro não encontrado na Google Books API.");

        var options = new SessionCreateOptions
        {
            PaymentMethodTypes = new List<string> { "card" },
            LineItems = new List<SessionLineItemOptions>
            {
                new()
                {
                    PriceData = new SessionLineItemPriceDataOptions
                    {
                        UnitAmount = (long)(saleTrade.Price * 100),
                        Currency = "eur",
                        ProductData = new SessionLineItemPriceDataProductDataOptions
                        {
                            Name = bookDetails.Title
                        }
                    },
                    Quantity = 1
                }
            },
            Mode = "payment",
            SuccessUrl = "https://reader-backendapi.azurewebsites.net/api/Payment/success?session_id={CHECKOUT_SESSION_ID}",
            CancelUrl = "https://reader-backendapi.azurewebsites.net/api/Payment/cancel",
            Metadata = new Dictionary<string, string>
            {
                { "SaleTradeId", saleTrade.Id.ToString() },
                { "BuyerId", currentUserId.ToString() } // Adiciona o BuyerId aos metadados
            }
        };

        try
        {
            var service = new SessionService();
            var session = await service.CreateAsync(options);

            return Ok(new { SessionId = session.Id, CheckoutUrl = session.Url });
        }
        catch (StripeException e)
        {
            return BadRequest(new { error = e.Message });
        }
    }

    /// <summary>
    /// Handles the Stripe webhook event, processing the received data for checkout session completions.
    /// </summary>
    /// <returns>An <see cref="IActionResult"/> indicating the result of the webhook processing. Returns success if the event is processed successfully, or an error message if a problem occurs during processing.</returns>
    [HttpPost("webhook")]
    public async Task<IActionResult> StripeWebhook()
    {
        var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();

        try
        {
            var stripeEvent = EventUtility.ConstructEvent(
                json,
                Request.Headers["Stripe-Signature"],
                _stripeSettings.WebhookSecret
            );

            if (stripeEvent.Type == "checkout.session.completed")
            {
                var session = stripeEvent.Data.Object as Session;

                // Recupera o PaymentIntent associado à sessão
                var paymentIntentId = session.PaymentIntentId;

                if (session.Metadata.ContainsKey("SaleTradeId"))
                {
                    // Lógica existente para SaleTrade (mantida como está)
                    var saleTradeId = int.Parse(session.Metadata["SaleTradeId"]);
                    var buyerId = int.Parse(session.Metadata["BuyerId"]);
                    // Processa a venda/troca...
                }

                if (session.Metadata.ContainsKey("BookId"))
                {
                    // Novo: lógica para atualizar o estado do WriterBook
                    var bookId = int.Parse(session.Metadata["BookId"]);

                    var book = await _context.WriterBooks.FindAsync(bookId);
                    if (book != null)
                    {
                        book.IsPromoted = true; // Atualiza o estado
                        await _context.SaveChangesAsync();
                        Console.WriteLine($"Livro {book.Title} promovido com sucesso.");
                    }
                    else
                    {
                        Console.WriteLine($"Livro com BookId {bookId} não encontrado.");
                    }
                }
            }

            return Ok();
        }
        catch (StripeException e)
        {
            return BadRequest(new { error = e.Message });
        }
    }

    /// <summary>
    /// Handles the success action triggered after a successful payment.
    /// </summary>
    /// <returns>An <see cref="IActionResult"/> indicating a successful payment completion message.</returns>
    [HttpGet("success")]
    public IActionResult Success()
    {
        return Ok("Pagamento realizado com sucesso!");
    }

    /// <summary>
    /// Handles requests to cancel a payment process and returns a confirmation message.
    /// </summary>
    /// <returns>An <see cref="IActionResult"/> containing the confirmation message of the cancellation.</returns>
    [HttpGet("cancel")]
    public IActionResult Cancel()
    {
        return Ok("Pagamento cancelado.");
    }
}