using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs.Sales;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.SaleTrades;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SaleTradeController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly INotificationService _notificationService;
    private readonly ITokenService _tokenService;


    public SaleTradeController(AppDbContext context, IGoogleBooksService bookService,
        INotificationService notificationService, ITokenService tokenService)
    {
        _context = context;
        _googleBooksService = bookService;
        _notificationService = notificationService;
        _tokenService = tokenService;
    }

    /// <summary>
    /// Asynchronously retrieves a list of friend IDs associated with a given user.
    /// </summary>
    /// <param name="userId">The ID of the user whose friends' IDs are to be retrieved.</param>
    /// <returns>A task representing the asynchronous operation, containing a list of friend IDs.</returns>
    [Authorize(Roles = "Leitor")]
    private async Task<List<int>> GetFriendIdsAsync(int userId)
    {
        return await _context.UserFriendship
            .Where(f => (f.RequesterId == userId || f.ReceiverId == userId) && f.IsConfirmed)
            .Select(f => f.RequesterId == userId ? f.ReceiverId : f.RequesterId)
            .ToListAsync();
    }

    /// <summary>
    /// Asynchronously retrieves a sale trade record by its unique identifier.
    /// </summary>
    /// <param name="id">The unique identifier of the sale trade to retrieve.</param>
    /// <returns>A task representing the asynchronous operation, containing the sale trade if found; otherwise, NotFound.</returns>
    [HttpGet("{id}")]
    [Authorize(Roles = "Leitor,ADMIN")]
    public async Task<ActionResult<SaleTrade>> GetSaleTrade(int id)
    {
        var saleTrade = await _context.SaleTrades.FindAsync(id);
        if (saleTrade == null) return NotFound();
        return saleTrade;
    }

    /// <summary>
    /// Creates a new sale or trade listing for a book based on the provided details.
    /// </summary>
    /// <param name="model">The details of the sale or trade to be created provided as a CreateSaleTradeDto object.</param>
    /// <returns>An IActionResult indicating the result of the operation, which includes the newly created sale or trade information upon successful creation.</returns>
    [HttpPost("create")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> CreateSaleTrade([FromBody] CreateSaleTradeDto model)
    {
        // Validação inicial
        if (!model.IsAvailableForSale && !model.IsAvailableForTrade)
            return BadRequest("O livro deve estar disponível para venda, troca ou ambas as opções.");

        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null)
            return Unauthorized("Utilizador não autenticado.");

        var userId = int.Parse(userIdClaim.Value);

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return Unauthorized("Utilizador não encontrado.");

        if (model.IsAvailableForSale && (!model.Price.HasValue || model.Price <= 0))
            return BadRequest("O preço deve ser maior que zero quando o livro está disponível para venda.");

        if (model.IsAvailableForTrade && string.IsNullOrEmpty(model.IsbnDesiredBook))
            return BadRequest("Um ISBN de livro desejado deve ser especificado quando o livro está disponível para troca.");

        // Busca ISBN do livro
        var isbn = await _googleBooksService.GetIsbnByTitle(model.Isbn);
        if (isbn == "ISBN não encontrado")
            return NotFound("Livro não encontrado na Google Books API.");

        // Adiciona uma pausa (ex: 1 segundo)
        await Task.Delay(1000); // Pausa de 1 segundo

        // Busca título do livro com base no ISBN
        var title = await _googleBooksService.GetTitleByIsbn(isbn);
        if (string.IsNullOrEmpty(title))
            return NotFound("Título do livro não encontrado na Google Books API.");

        // Busca ISBN do livro desejado, se aplicável
        string? isbnDesired = null;
        string? desiredBookTitle = null;
        if (model.IsAvailableForTrade && !string.IsNullOrEmpty(model.IsbnDesiredBook))
        {
            isbnDesired = await _googleBooksService.GetIsbnByTitle(model.IsbnDesiredBook);
            if (isbnDesired == "ISBN não encontrado")
                return NotFound("Livro desejado para troca não encontrado na Google Books API.");

            // Adiciona uma pausa antes de buscar o título do livro desejado
            await Task.Delay(1000); // Pausa de 1 segundo

            // Buscar título do livro desejado
            desiredBookTitle = await _googleBooksService.GetTitleByIsbn(isbnDesired);
        }

        // Criação do SaleTrade
        var saleTrade = new SaleTrade
        {
            IdUser = userId,
            Isbn = isbn,
            Title = title, // Armazena o título do livro principal
            Price = model.IsAvailableForSale ? model.Price : null,
            IsAvailableForSale = model.IsAvailableForSale,
            IsAvailableForTrade = model.IsAvailableForTrade,
            State = model.State,
            Notes = model.Notes,
            IsbnDesiredBook = isbnDesired,
            DesiredBookTitle = desiredBookTitle, // Título do livro desejado
            DateCreation = DateTime.UtcNow
        };

        // Adiciona a SaleTrade no contexto e salva
        _context.SaleTrades.Add(saleTrade);
        await _context.SaveChangesAsync();

        // Notifica os amigos sobre a nova venda ou troca
        await _notificationService.NotifyFriendsOfNewSale(userId, isbn, model.IsAvailableForSale,
            model.IsAvailableForTrade);

        // Retorna o resultado da criação
        return CreatedAtAction(nameof(GetSaleTrade), new { id = saleTrade.Id }, saleTrade);
    }

    /// <summary>
    /// Edits an existing sale or trade offer associated with the logged-in user.
    /// </summary>
    /// <param name="id">The unique identifier of the sale trade to be edited.</param>
    /// <param name="model">The data transfer object containing the updated details of the sale trade.</param>
    /// <returns>An IActionResult indicating the outcome of the edit operation, such as success or relevant error messages.</returns>
    [HttpPut("edit-own-sale/{id}")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> EditSaleTrade(int id, [FromBody] CreateSaleTradeDto model)
    {
        int currentUserId;
        try
        {
            currentUserId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Usuário não autenticado.");
        }

        var saleTrade = await _context.SaleTrades.FindAsync(id);
        if (saleTrade == null) return NotFound("Anúncio não encontrado.");

        if (saleTrade.IdUser != currentUserId) return Unauthorized("Apenas o dono do anúncio pode editá-lo.");

        if (!model.IsAvailableForSale && !model.IsAvailableForTrade)
            return BadRequest("O livro deve estar disponível para venda, troca ou ambas as opções.");

        if (model.IsAvailableForSale && (!model.Price.HasValue || model.Price <= 0))
            return BadRequest("O preço deve ser maior que zero quando o livro está disponível para venda.");

        if (model.IsAvailableForTrade && string.IsNullOrEmpty(model.IsbnDesiredBook))
            return BadRequest(
                "Um ISBN de livro desejado deve ser especificado quando o livro está disponível para troca.");

        saleTrade.Isbn = model.Isbn;
        saleTrade.Price = model.IsAvailableForSale ? model.Price : null;
        saleTrade.IsAvailableForSale = model.IsAvailableForSale;
        saleTrade.IsAvailableForTrade = model.IsAvailableForTrade;
        saleTrade.State = model.State;
        saleTrade.Notes = model.Notes;
        saleTrade.IsbnDesiredBook = model.IsAvailableForTrade ? model.IsbnDesiredBook : null;

        await _context.SaveChangesAsync();

        return Ok(saleTrade);
    }

    /// <summary>
    /// Asynchronously deletes a sale trade entry by its identifier if the current user is the owner.
    /// </summary>
    /// <param name="id">The identifier of the sale trade to be deleted.</param>
    /// <returns>An IActionResult representing the result of the operation, which could be
    /// NoContent if successful,
    /// Unauthorized if the user is not authenticated,
    /// NotFound if the sale trade does not exist,
    /// or Forbid if the user is not allowed to delete the sale trade.</returns>
    [HttpDelete("delete-own-sale/{id}")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> DeleteSaleTrade(int id)
    {
        int currentUserId;

        try
        {
            currentUserId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado.");
        }

        var saleTrade = await _context.SaleTrades.FindAsync(id);
        if (saleTrade == null)
            return NotFound("Anúncio não encontrado.");

        if (saleTrade.IdUser != currentUserId)
            return Forbid("Apenas o dono do anúncio pode excluí-lo.");

        _context.SaleTrades.Remove(saleTrade);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Retrieves the sale trades associated with a specific friend of the authenticated user.
    /// </summary>
    /// <param name="friendId">The ID of the friend whose sale trades are to be retrieved.</param>
    /// <returns>An action result containing an enumerable of sale trades belonging to the specified friend.</returns>
    [HttpGet("friends/specific/{friendId}")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<SaleTrade>>> GetSpecificFriendSaleTrades(int friendId)
    {
        int userId;

        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado.");
        }

        // Obter IDs dos amigos
        var friendIds = await GetFriendIdsAsync(userId);

        // Validar se o utilizador-alvo é realmente um amigo
        if (!friendIds.Contains(friendId))
            return BadRequest("O utilizador selecionado não é amigo do utilizador atual.");

        // Buscar as vendas do amigo
        var friendSaleTrades = await _context.SaleTrades
            .Where(st => st.IdUser == friendId)
            .ToListAsync();

        return Ok(friendSaleTrades);
    }

    /// <summary>
    /// Asynchronously retrieves a specific sale trade related to a friend's transaction based on the sale identifier.
    /// </summary>
    /// <param name="saleId">The unique identifier of the sale trade to be retrieved.</param>
    /// <returns>A task representing the asynchronous operation, containing the details of the specific sale trade if found.</returns>
    [HttpGet("GetSpecificFriendSaleTrade/{saleId}")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<SaleTrade>>> GetSpecificFriendSaleTrade(int saleId)
    {
        int userId;
        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado");
        }

        var saleTrade = await _context.SaleTrades
            .Where(st => st.Id == saleId && _context.UserFriendship.Any(f =>
                ((f.RequesterId == userId && f.ReceiverId == st.IdUser) ||
                 (f.RequesterId == st.IdUser && f.ReceiverId == userId)) &&
                f.IsConfirmed))
            .FirstOrDefaultAsync();

        return Ok(saleTrade);
    }

    /// <summary>
    /// Retrieves a specific sale trade offer based on the provided offer ID.
    /// </summary>
    /// <param name="offerId">The ID of the sale trade offer to retrieve.</param>
    /// <returns>An action result containing the sale trade offer if found, or a not found response if the offer does not exist.</returns>
    [HttpGet("offers-received/{offerId}")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<SaleTradeOffer>> GetSaleTradeOffer(int offerId)
    {
        var saleTradeOffer = await _context.SaleTradeOffers.FindAsync(offerId);

        if (saleTradeOffer == null)
            return NotFound("Oferta não encontrada.");

        return Ok(saleTradeOffer);
    }

    /// <summary>
    /// Retrieves a list of sale trade offers associated with a specific sale trade.
    /// </summary>
    /// <param name="id">The ID of the sale trade for which the offers are to be retrieved.</param>
    /// <returns>An asynchronous task that returns an action result containing a list of sale trade offers.</returns>
    [HttpGet("{id}/offers")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<SaleTradeOffer>>> GetSaleTradeOffers(int id)
    {
        var saleTradeOffers = await _context.SaleTradeOffers
            .Where(offer => offer.IdSaleTrade == id)
            .ToListAsync();

        return Ok(saleTradeOffers);
    }

    /// <summary>
    /// Handles the decision on a sale or trade offer, either accepting or declining it,
    /// and performs associated actions such as updating trade availability and notifying users.
    /// </summary>
    /// <param name="offerId">The unique identifier of the offer to be decided upon.</param>
    /// <param name="decision">The decision object indicating whether the offer is accepted or declined.</param>
    /// <returns>An IActionResult indicating the success or failure of the operation, with appropriate messages.</returns>
    [HttpPost("offer/{offerId}/decision")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> DecideSaleTradeOffer(int offerId, [FromBody] SaleTradeOfferDecisionDto decision)
    {
        var userId = _tokenService.GetUserIdByToken();

        var offer = await _context.SaleTradeOffers.FindAsync(offerId);
        if (offer == null)
            return NotFound("Oferta não encontrada.");

        var saleTrade = await _context.SaleTrades.FindAsync(offer.IdSaleTrade);
        if (saleTrade == null)
            return NotFound("Anúncio de venda/troca associado à oferta não encontrado.");

        if (saleTrade.IdUser != userId)
            return Forbid("Não tem permissão para decidir sobre esta oferta.");

        if (decision.Accept)
        {
            // Aceitar a oferta
            offer.Declined = false;
            saleTrade.IsAvailableForSale = false;
            saleTrade.IsAvailableForTrade = false;

            // Remover o SaleTrade de todas as wishlists
            var wishlistEntries = _context.Wishlists.Where(w => w.SaleTradeId == saleTrade.Id);
            _context.Wishlists.RemoveRange(wishlistEntries);

            // Atualizar o status da oferta
            saleTrade.Notes = "Aceite";
            await _context.SaveChangesAsync();

            // Notificações
            await _notificationService.NotifySellerOfTradeCompletion(saleTrade.IdUser, saleTrade.Isbn);
            await _notificationService.NotifyBuyerOfTradeCompletion(offer.IdUser, saleTrade.Isbn);

            return Ok(new { success = true, message = "Oferta aceite com sucesso." });
        }
        else
        {
            // Recusar a oferta
            offer.Declined = true;
            await _context.SaveChangesAsync();

            // Notificação
            await _notificationService.NotifyUserOfTradeRejection(offer.IdUser, saleTrade.Isbn);

            return Ok(new { success = true, message = "Oferta recusada com sucesso." });
        }
    }

    /// <summary>
    /// Asynchronously retrieves a list of sale trade offers received by the current user that have not been declined.
    /// </summary>
    /// <returns>A task representing the asynchronous operation, containing a list of sale trade offers with associated titles.</returns>
    [HttpGet("offers-received")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<dynamic>>> GetOffersReceived()
    {
        var userId = _tokenService.GetUserIdByToken();

        var offers = await _context.SaleTradeOffers
            .Where(o => _context.SaleTrades
                                .Where(s => s.IdUser == userId)
                                .Select(s => s.Id)
                                .Contains(o.IdSaleTrade) && !o.Declined)
            .ToListAsync();

        if (!offers.Any())
        {
            return NotFound("Nenhuma oferta recebida.");
        }

        // Lista para armazenar os resultados com títulos
        var offersWithTitles = new List<dynamic>();

        foreach (var offer in offers)
        {
            try
            {
                // Busque o SaleTrade associado à oferta
                var saleTrade = await _context.SaleTrades.FindAsync(offer.IdSaleTrade);

                if (saleTrade == null)
                {
                    continue; // Pula caso não encontre a venda associada
                }

                // Obtenha o título do livro usando a função GetTitleByIsbn
                string title = "Título não encontrado";

                try
                {
                    title = await _googleBooksService.GetTitleByIsbn(saleTrade.Isbn);
                    if (string.IsNullOrEmpty(title))
                    {
                        title = "Título inválido ou vazio";
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Erro ao buscar título: {ex.Message}");
                    title = "Erro ao buscar título";
                }


                // Adiciona os dados da oferta com o título ao resultado
                offersWithTitles.Add(new
                {
                    offer.IdOffer,
                    offer.IdUser,
                    offer.IsbnOfferedBook,
                    offer.Message,
                    offer.DateOffered,
                    offer.Declined,
                    offer.IdSaleTrade,
                    SaleTradeIsbn = saleTrade.Isbn,
                    SaleTradeTitle = title, // Título obtido
                    SaleTradePrice = saleTrade.Price,
                    SaleTradeNotes = saleTrade.Notes
                });
            }
            catch (Exception ex)
            {
                // Log de erro
                Console.WriteLine($"Erro ao processar oferta {offer.IdOffer}: {ex.Message}");
            }
        }

        return Ok(offersWithTitles);
    }

    /// <summary>
    /// Asynchronously retrieves a list of sales associated with the authenticated user.
    /// </summary>
    /// <returns>A task representing the asynchronous operation, containing a list of sales with detailed information.</returns>
    [HttpGet("my-sales")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<object>>> GetMySales()
    {
        int userId;

        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado.");
        }

        var mySales = await _context.SaleTrades
            .Where(st => st.IdUser == userId)
            .ToListAsync();

        var tasks = mySales.Select(async sale =>
        {
            string title = "Título não encontrado";
            string? desiredBookTitle = null;

            try
            {
                // Buscar o título do livro principal
                title = await _googleBooksService.GetTitleByIsbn(sale.Isbn) ?? "Título não encontrado";
            }
            catch
            {
                title = "Erro ao obter título";
            }

            if (sale.IsAvailableForTrade && !string.IsNullOrEmpty(sale.IsbnDesiredBook))
            {
                try
                {
                    // Buscar o título do livro desejado
                    desiredBookTitle = await _googleBooksService.GetTitleByIsbn(sale.IsbnDesiredBook)
                                      ?? "Livro desejado não disponível.";
                }
                catch
                {
                    desiredBookTitle = "Erro ao obter o título do livro desejado.";
                }
            }

            return new
            {
                sale.Id,
                sale.IdUser,
                sale.Isbn,
                Title = title,
                sale.IsbnDesiredBook,
                DesiredBookTitle = desiredBookTitle,
                sale.Price,
                sale.IsAvailableForSale,
                sale.IsAvailableForTrade,
                sale.State,
                sale.Notes,
                sale.DateCreation
            };
        });

        var salesWithTitles = await Task.WhenAll(tasks);
        return Ok(salesWithTitles);
    }


    /// <summary>
    /// Asynchronously retrieves a list of sale trade offers with their status for the authenticated user.
    /// </summary>
    /// <returns>A task representing the asynchronous operation, containing an action result with an enumerable list of sale trade offers and their respective status.</returns>
    [HttpGet("offers-decisions")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<object>>> GetOffersWithStatus()
    {
        int userId;

        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado.");
        }

        var offers = await _context.SaleTradeOffers
            .Join(
                _context.SaleTrades,
                offer => offer.IdSaleTrade,
                trade => trade.Id,
                (offer, trade) => new
                {
                    offer.IdOffer,
                    offer.IdUser,
                    offer.IsbnOfferedBook,
                    offer.Message,
                    offer.DateOffered,
                    offer.Declined,
                    SaleTradeOwnerId = trade.IdUser,
                    Status = offer.Declined ? "Recusada" : (!trade.IsAvailableForTrade ? "Aceita" : "Pendente"),
                    SaleTradeIsbn = trade.Isbn,
                    SaleTradeNotes = trade.Notes
                }
            )
            .Where(o => o.SaleTradeOwnerId == userId || o.IdUser == userId)
            .ToListAsync();

        if (!offers.Any())
            return NotFound("Nenhuma oferta encontrada.");

        var offersWithTitles = new List<object>();

        foreach (var offer in offers)
        {
            string title = "Título não encontrado";
            string offeredBookTitle = "Título não encontrado";

            try
            {
                // Buscar o título do livro principal
                title = await _googleBooksService.GetTitleByIsbn(offer.SaleTradeIsbn) ?? "Título inválido ou vazio";
            }
            catch
            {
                title = "Erro ao buscar título";
            }

            try
            {
                // Buscar o título do livro oferecido
                offeredBookTitle = await _googleBooksService.GetTitleByIsbn(offer.IsbnOfferedBook) ?? "Título inválido ou vazio";
            }
            catch
            {
                offeredBookTitle = "Erro ao buscar título do livro oferecido";
            }

            offersWithTitles.Add(new
            {
                offer.IdOffer,
                offer.IdUser,
                offer.IsbnOfferedBook,
                OfferedBookTitle = offeredBookTitle,
                offer.Message,
                offer.DateOffered,
                offer.Declined,
                offer.SaleTradeOwnerId,
                offer.Status,
                SaleTradeTitle = title,
                offer.SaleTradeNotes
            });
        }

        return Ok(offersWithTitles);
    }

    // POST: api/saletrade/{id}/trade-offer
    /// <summary>
    /// Asynchronously creates a sale trade offer for a specified sale/trade advertisement.
    /// </summary>
    /// <param name="id">The ID of the sale/trade advertisement for which the offer is being made.</param>
    /// <param name="model">An instance of CreateSaleTradeOfferDto containing details of the offered trade, such as the ISBN of the book being offered.</param>
    /// <returns>An IActionResult indicating the result of the operation, including creation status and any errors encountered.</returns>
    [HttpPost("{id}/trade-offer")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> CreateSaleTradeOffer(int id, [FromBody] CreateSaleTradeOfferDto model)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null)
        {
            return Unauthorized("Não foi possível identificar o utilizador.");
        }
        int currentUserId = int.Parse(userIdClaim.Value);

        var user = await _context.Users.FindAsync(currentUserId);
        if (user == null)
        {
            return NotFound("O utilizador associado à oferta não foi encontrado.");
        }

        var saleTrade = await _context.SaleTrades.FindAsync(id);
        if (saleTrade == null)
        {
            return NotFound("Anúncio de venda/troca não encontrado.");
        }

        bool isTradeAvailable = saleTrade.IsAvailableForTrade &&
                               !await _context.SaleTradeOffers.AnyAsync(offer => offer.IdSaleTrade == id && !offer.Declined);

        if (!isTradeAvailable)
        {
            return BadRequest("Este anúncio já não está disponível para troca.");
        }

        if (saleTrade.IdUser == currentUserId)
        {
            return BadRequest("Não pode fazer uma oferta para o seu próprio anúncio.");
        }

        bool isFriend = await _context.UserFriendship.AnyAsync(uf =>
           ((uf.RequesterId == currentUserId && uf.ReceiverId == saleTrade.IdUser) ||
            (uf.RequesterId == saleTrade.IdUser && uf.ReceiverId == currentUserId)) &&
            uf.IsConfirmed);

        if (!isFriend)
        {
            return Unauthorized("Apenas amigos podem fazer ofertas de troca neste anúncio.");
        }

        var isbn = await _googleBooksService.GetIsbnByTitle(model.IsbnOfferedBook);
        if (isbn == "ISBN não encontrado")
        {
            return NotFound("Livro não encontrado na Google Books API.");
        }

        var saleTradeOffer = new SaleTradeOffer
        {
            IdUser = currentUserId,
            IsbnOfferedBook = isbn,
            Message = model.Message,
            IdSaleTrade = id,
            DateOffered = DateTime.UtcNow
        };

        _context.SaleTradeOffers.Add(saleTradeOffer);
        await _context.SaveChangesAsync();

        return CreatedAtAction("GetSaleTradeOffer", new { offerId = saleTradeOffer.IdOffer }, saleTradeOffer);
    }

    /// <summary>
    /// Asynchronously retrieves sale trades of the authenticated user's friends.
    /// </summary>
    /// <returns>A task representing the asynchronous operation that returns an action result with an enumeration of objects containing friend sale trade details.</returns>
    [HttpGet("friends-sales")]
    [Authorize(Roles = "Leitor")]
    public async Task<ActionResult<IEnumerable<object>>> GetFriendsSaleTrades()
    {
        int userId;

        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized("Utilizador não autenticado.");
        }

        // Obter IDs dos amigos
        var friendIds = await GetFriendIdsAsync(userId);

        // Buscar vendas
        var friendsSaleTrades = await _context.SaleTrades
            .Where(st => friendIds.Contains(st.IdUser))
            .ToListAsync();

        var result = new List<object>();

        // Iterar sobre as vendas para obter os títulos
        foreach (var sale in friendsSaleTrades)
        {
            string title;
            try
            {
                title = await _googleBooksService.GetTitleByIsbn(sale.Isbn);
                title = string.IsNullOrEmpty(title) ? "Título não disponível" : title;
            }
            catch
            {
                title = "Erro ao obter título";
            }

            string? desiredBookTitle = null;
            if (sale.IsAvailableForTrade) // Apenas busca o título se IsAvailableForTrade for true
            {
                try
                {
                    desiredBookTitle = await _googleBooksService.GetTitleByIsbn(sale.IsbnDesiredBook);
                    desiredBookTitle = string.IsNullOrEmpty(desiredBookTitle)
                        ? "Livro desejado não disponível."
                        : desiredBookTitle;
                }
                catch
                {
                    desiredBookTitle = "Erro ao obter o título do livro desejado.";
                }
            }

            // Adicionar ao resultado
            result.Add(new
            {
                sale.Id,
                sale.Isbn,
                Title = title,
                DesiredBookTitle = desiredBookTitle,
                sale.Price,
                sale.IsAvailableForSale,
                sale.IsAvailableForTrade,
                sale.State,
                sale.Notes,
                sale.DateCreation,
                sale.IdUser,
                Username = await _context.Users
                    .Where(u => u.Id == sale.IdUser)
                    .Select(u => u.Username)
                    .FirstOrDefaultAsync()
            });
        }

        return Ok(result);
    }

    
}
