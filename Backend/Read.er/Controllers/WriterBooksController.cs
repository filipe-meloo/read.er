using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Read.er.Data;
using Read.er.DTOs.WriterBooks;
using Read.er.Enumeracoes.Books;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Book;
using Read.er.Models.SaleTrades;
using Stripe;
using Stripe.Checkout;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WriterBooksController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly StripeSettings _stripeSettings;
    private readonly ITokenService _tokenService;


    public WriterBooksController(AppDbContext context, IGoogleBooksService googleBooksService,
        IOptions<StripeSettings> stripeSettings, ITokenService tokenService)
    {
        _context = context;
        _googleBooksService = googleBooksService;
        _stripeSettings = stripeSettings?.Value ?? throw new ArgumentNullException(nameof(stripeSettings));
        _tokenService = tokenService;
        StripeConfiguration.ApiKey = _stripeSettings.SecretKey;
    }

    /// <summary>
    /// Adds a new writer book to the database.
    /// </summary>
    /// <param name="dto">Data transfer object containing the ISBN and price of the book to be added.</param>
    /// <returns>A task representing the asynchronous operation, with an IActionResult indicating the result of the action:
    /// - 200 OK if the book is successfully added and is pending approval.
    /// - 400 Bad Request if the ISBN length is invalid or the price is not greater than zero.
    /// - 404 Not Found if book details could not be fetched for the given ISBN.
    /// - 409 Conflict if the book already exists in the writer's list.</returns>
    [HttpPost("add")]
    [Authorize(Roles = "Autor")]
    public async Task<IActionResult> AddWriterBook([FromBody] AddWriterBookDto dto)
    {
        var userId = _tokenService.GetUserIdByToken();

        if (dto.ISBN.Length != 10 && dto.ISBN.Length != 13) return BadRequest("O ISBN deve ter 10 ou 13 caracteres.");

        if (dto.Price <= 0) return BadRequest("O preço deve ser maior que zero.");

        var existingBook = await _context.WriterBooks
            .FirstOrDefaultAsync(b => b.Isbn == dto.ISBN && b.WriterId == userId);

        if (existingBook != null) return Conflict("Esta obra já existe na sua lista.");

        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(dto.ISBN);
        if (bookDetails == null) return NotFound("Informações do livro não encontradas para o ISBN fornecido.");

        var newBook = new WriterBook
        {
            Isbn = dto.ISBN,
            Title = bookDetails.Title,
            Author = bookDetails.Author,
            Description = bookDetails.Description,
            PublishDate = bookDetails.PublishDate ?? DateTime.MinValue,
            Price = dto.Price ?? bookDetails.Price ?? 0,
            WriterId = userId,
            Status = WriterBookStatus.Pending
        };

        _context.WriterBooks.Add(newBook);
        await _context.SaveChangesAsync();

        return Ok("Obra adicionada com sucesso e está pendente para aprovação.");
    }

    [HttpGet("isPromoted/{isbn}")]
    public async Task<IActionResult> isPromoted(string isbn) {

        var book = await _context.WriterBooks
            .FirstOrDefaultAsync(b => b.Isbn == isbn);


        if (book == null)
        {
            return BadRequest("Livro não encontrado!");
        }

        return Ok(book.IsPromoted);
    }

    /// <summary>
    /// Edits an existing writer book's details in the database.
    /// </summary>
    /// <param name="id">The unique identifier of the book to be edited.</param>
    /// <param name="dto">Data transfer object containing the updated title, author, and description of the book.</param>
    /// <returns>A task representing the asynchronous operation, with an IActionResult indicating the result:
    /// <list type="bullet">
    /// <item>Ok if the book is updated successfully.</item>
    /// <item>NotFound if the book is not found.</item>
    /// <item>BadRequest if the title is missing or exceeds the allowed length, or if the description exceeds the allowed length.</item>
    /// </list>
    [HttpPut("edit/{id}")]
    [Authorize(Roles = "Autor")]
    public async Task<IActionResult> EditWriterBook(int id, [FromBody] EditWriterBookDto dto)
    {
        var book = await _context.WriterBooks.FindAsync(id);
        if (book == null)
            return NotFound("Book not found.");

        if (string.IsNullOrEmpty(dto.Title) || dto.Title.Length > 200)
            return BadRequest("O título é obrigatório e não pode exceder 200 caracteres.");

        if (dto.Description != null && dto.Description.Length > 500)
            return BadRequest("A descrição não pode exceder 500 caracteres.");

        book.Title = dto.Title;
        book.Author = dto.Author;
        book.Description = dto.Description;

        await _context.SaveChangesAsync();

        return Ok("Book updated successfully.");
    }

    /// <summary>
    /// Removes a writer book from the database using the specified book ID.
    /// </summary>
    /// <param name="id">The unique identifier of the writer book to remove.</param>
    /// <returns>A task representing the asynchronous operation, with an IActionResult indicating the result of the action:
    /// - 200 OK if the book is successfully removed.
    /// - 404 Not Found if no book is found with the specified ID.</returns>
    [HttpDelete("remove/{id}")]
    public async Task<IActionResult> RemoveWriterBook(int id)
    {
        var book = await _context.WriterBooks.FindAsync(id);
        if (book == null)
            return NotFound("Book not found.");

        _context.WriterBooks.Remove(book);
        await _context.SaveChangesAsync();

        return Ok("Book removed successfully.");
    }

    /// <summary>
    /// Retrieves a list of approved books for the current writer.
    /// </summary>
    /// <returns>A task that represents the asynchronous operation. The task result contains an IActionResult with:
    /// - 200 OK and a list of approved book details if books are found.
    /// - 400 Bad Request if the writerId cannot be retrieved.</returns>
    [HttpGet("list-approved")]
    public async Task<IActionResult> ListApprovedBooks()
    {
        var writerId = _tokenService.GetUserIdByToken();
        if (writerId == null)
        {
            return BadRequest("writedId not found");
        }
        var approvedBooks = await _context.WriterBooks
            .Where(b => b.Status == WriterBookStatus.Approved && b.WriterId == writerId)
            .ToListAsync();

        var booksDto = new List<BookDetailsDto>();

        foreach (var book in approvedBooks)
        {
            // Chama o GoogleBooksService para obter os detalhes do livro usando o ISBN
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(book.Isbn);

            // Cria um DTO para o livro e adiciona na lista
            var bookDto = new BookDetailsDto
            {
                Id = book.Id,
                ISBN = book.Isbn,
                Title = book.Title,
                Author = book.Author,
                CoverUrl = bookDetails?.CoverUrl,
                VolumeId = bookDetails.VolumeId, // A URL da capa obtida via GoogleBooksService
                Description = bookDetails.Description
            };

            booksDto.Add(bookDto);
        }

        // Retorna a lista de livros com os detalhes, incluindo a capa
        return Ok(booksDto);
    }

    /// <summary>
    /// Retrieves a list of books that are currently pending approval,
    /// along with their detailed information including cover URL.
    /// </summary>
    /// <returns>A task representing the asynchronous operation,
    /// with an IActionResult containing the list of pending books:
    /// - 200 OK with a list of books in BookDetailsDto format if retrieval is successful.</returns>
    [HttpGet("list-pendingBooks")]
    public async Task<IActionResult> ListBooks()
    {
        var pendingBooks = await _context.WriterBooks
            .Where(b => b.Status == WriterBookStatus.Pending)
            .ToListAsync();

        var booksDto = new List<BookDetailsDto>();

        foreach (var book in pendingBooks)
        {
            // Chama o GoogleBooksService para obter os detalhes do livro usando o ISBN
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(book.Isbn);

            // Cria um DTO para o livro e adiciona na lista
            var bookDto = new BookDetailsDto
            {
                Id = book.Id,
                Title = book.Title,
                Author = book.Author,
                CoverUrl = bookDetails?.CoverUrl,
                VolumeId = bookDetails.VolumeId,// A URL da capa obtida via GoogleBooksService
                Description = bookDetails.Description
            };

            booksDto.Add(bookDto);
        }

        // Retorna a lista de livros com os detalhes, incluindo a capa
        return Ok(booksDto);
    }

    /// <summary>
    /// Retrieves a book cover image from a remote URL and returns it as a file.
    /// </summary>
    /// <param name="imageUrl">The URL of the image to be retrieved.</param>
    /// <returns>A task representing the asynchronous operation, with an IActionResult containing the image file:
    /// - Returns a file with the retrieved image and its content type if successful.
    /// - Returns 400 Bad Request if the image URL is empty or the image cannot be fetched.
    /// - Returns 500 Internal Server Error if an exception occurs during the image retrieval.</returns>
    [HttpGet("book-cover-proxy-2")]
    public async Task<IActionResult> GetBookCoverProxyWriters(string imageUrl)
    {
        if (string.IsNullOrEmpty(imageUrl))
        {
            return BadRequest("A URL da imagem é obrigatória.");
        }

        try
        {
            var httpClient = new HttpClient();

            var userId = _tokenService.GetUserIdByToken();

            var response = await httpClient.GetAsync(imageUrl);

            if (!response.IsSuccessStatusCode)
            {
                return BadRequest("Falha ao buscar a imagem de capa.");
            }

            var contentType = response.Content.Headers.ContentType?.ToString();
            var content = await response.Content.ReadAsByteArrayAsync();

            return File(content, contentType ?? "image/jpeg");
        }
        catch (Exception)
        {
            return StatusCode(500, "Erro ao buscar a imagem de capa.");
        }
    }

    /// <summary>
    /// Retrieves a list of approved writer books from the database and returns their details.
    /// </summary>
    /// <returns>A task that represents the asynchronous operation. The task result contains an IActionResult with the list of approved writer book details as BookDetailsDto:
    /// - 200 OK if the list is successfully retrieved.
    /// - An appropriate error response if there is a failure during retrieval.</returns>
    [HttpGet("list-WriterBooks")]
    [Authorize(Roles = "Autor, Admin")]
    public async Task<IActionResult> ListWriterBooks()
    {
        // Recupera os livros aprovados do banco de dados
        var approvedBooks = await _context.WriterBooks.Where(b => b.Status == WriterBookStatus.Approved).ToListAsync();

        // Lista para armazenar os DTOs com os detalhes dos livros
        var booksDto = new List<BookDetailsDto>();

        foreach (var book in approvedBooks)
        {
            // Chama o GoogleBooksService para obter os detalhes do livro usando o ISBN
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(book.Isbn);

            // Cria um DTO para o livro e adiciona na lista
            var bookDto = new BookDetailsDto
            {
                Title = book.Title,
                Author = book.Author,
                CoverUrl = bookDetails?.CoverUrl,
                VolumeId = bookDetails.VolumeId// A URL da capa obtida via GoogleBooksService
            };

            booksDto.Add(bookDto);
        }

        // Retorna a lista de livros com os detalhes, incluindo a capa
        return Ok(booksDto);
    }

    /// <summary>
    /// Retrieves the status of a writer's book by its ID.
    /// </summary>
    /// <param name="bookId">The unique identifier of the book whose status is to be retrieved.</param>
    /// <returns>A task representing the asynchronous operation, with an IActionResult indicating the result:
    /// - 200 OK with the status of the book if the book exists and is owned by the requesting writer.
    /// - 401 Unauthorized if the book is owned by a different writer.
    /// - 404 Not Found if the book does not exist.</returns>
    [HttpGet("get-book-status/{bookId}")]
    [Authorize(Roles = "Autor")]
    public async Task<IActionResult> GetBookStatus(int bookId)
    {
        var book = await _context.WriterBooks.FindAsync(bookId);

        if (book == null) return NotFound("Obra não encontrada.");

        if (book.WriterId != _tokenService.GetUserIdByToken())
            return Unauthorized("Você não tem permissão para acessar o status desta obra.");

        return Ok(book.Status);
    }

    /// <summary>
    /// Initiates a promotion process for a specified book.
    /// </summary>
    /// <param name="id">The unique identifier of the book to be promoted.</param>
    /// <returns>A task representing the asynchronous operation, containing an IActionResult with the result of the action:
    /// - 200 OK with session id and checkout URL if the promotion is successfully initiated.
    /// - 400 Bad Request if the book is already promoted or if there is an issue with the payment process.
    /// - 401 Unauthorized if the user does not have permission to promote the book.
    /// - 404 Not Found if the book is not found in the database.</returns>
    [Authorize(Roles = "Autor")]
    [HttpPost("promote/{isbn}")]
    public async Task<IActionResult> PromoteBook(string isbn)
    {
        try
        {
            var userId = _tokenService.GetUserIdByToken();

            var book = await _context.WriterBooks.Where(b => b.Isbn == isbn).FirstAsync();

            if (book == null)
                return NotFound("Livro não encontrado.");

            if (book.WriterId != userId)
                return Unauthorized("Você não tem permissão para promover este livro.");

            if (book.IsPromoted)
                return BadRequest("Este livro já está promovido.");

            var promotionAmount = 500;

            var sessionService = new SessionService(new StripeClient(_stripeSettings.SecretKey));

            var options = new SessionCreateOptions
            {
                PaymentMethodTypes = new List<string> { "card" },
                LineItems = new List<SessionLineItemOptions>
                {
                    new()
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            UnitAmount = promotionAmount,
                            Currency = "eur",
                            ProductData = new SessionLineItemPriceDataProductDataOptions
                            {
                                Name = $"Promoção para {book.Title}"
                            }
                        },
                        Quantity = 1
                    }
                },
                Mode = "payment",
                SuccessUrl = Url.Action("Success", "Payment", null, Request.Scheme) +
                             "?session_id={CHECKOUT_SESSION_ID}",
                CancelUrl = Url.Action("Cancel", "Payment", null, Request.Scheme),
                Metadata = new Dictionary<string, string>
                {
                    { "BookId", book.Id.ToString() }
                }
            };

            try
            {
                var session = await sessionService.CreateAsync(options);
                return Ok(new { SessionId = session.Id, CheckoutUrl = session.Url });
            }
            catch (StripeException e)
            {
                return BadRequest(new { error = e.Message });
            }
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ex.Message);
        }
    }
}