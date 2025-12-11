using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs.LibraryBook;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models.Book;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Leitor")]
public class PersonalLibraryController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly RecommendationService _recommendationService;
    private readonly ILibraryService _libraryService;
    private readonly ITokenService _tokenService;
    private readonly Read.er.Interfaces.IBookService _bookService;

    public PersonalLibraryController(AppDbContext context, IGoogleBooksService googleBooksService,
        RecommendationService recommendationService, ILibraryService libraryService, ITokenService tokenService, IBookService bookService)
    {
        _context = context;
        _googleBooksService = googleBooksService;
        _recommendationService = recommendationService;
        _libraryService = libraryService;
        _tokenService = tokenService;
        _bookService = bookService;
    }

    /// <summary>
    /// Adds a book to the personal library based on the provided data transfer object.
    /// </summary>
    /// <param name="model">An object containing the information needed to add a book to the library, including the title, status, pages read, and the date read.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> representing the result of the operation, which may be a success status if the book is added successfully,
    /// or a corresponding error status in cases of validation failure or if the book is already in the library.
    /// </returns>
    [HttpPost("addToLibrary")]
    public async Task<IActionResult> AddBookToLibrary([FromBody] AddBookToLibraryDto model)
    {
        var userId = _tokenService.GetUserIdByToken();

        if (string.IsNullOrEmpty(model.Title))
            return BadRequest("O título do livro é obrigatório.");

        var Isbn = await _googleBooksService.GetIsbnByTitle(model.Title);
        if (Isbn == "Isbn não encontrado")
            return NotFound("Isbn não encontrado para o título especificado.");

        if (Isbn.Length < 10 || Isbn.Length > 13)
            return BadRequest("O Isbn deve ter entre 10 e 13 caracteres.");

        var existingBook = await _context.PersonalLibraries
            .FirstOrDefaultAsync(b => b.Isbn == Isbn && b.UserId == userId);

        if (existingBook != null)
            return Conflict("O livro já está na Biblioteca Pessoal.");

        // Obter detalhes do livro, como número de páginas
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(Isbn);
        if (bookDetails == null)
            return NotFound("Detalhes do livro não encontrados.");

        // Validações baseadas no status
        if (model.Status == Status.Read)
        {
            if (!model.DateRead.HasValue)
                return BadRequest("A data em que o livro foi lido é obrigatória para o status 'Read'.");

            // Se o status for Read, o número de páginas lidas deve ser igual ao total de páginas
            model.PagesRead = (int)bookDetails.Length;
        }
        else if (model.Status == Status.Tbr || model.Status == Status.Current_Read)
        {
            if (model.PagesRead > bookDetails.Length)
                return BadRequest("O número de páginas lidas não pode ser maior que o total de páginas do livro.");
        }

        // Criação do item na biblioteca pessoal
        var libraryItem = new PersonalLibrary
        {
            UserId = userId,
            Isbn = Isbn,
            Title = bookDetails.Title,
            Author = bookDetails.Author,
            Description = bookDetails.Description,
            Genres = bookDetails.Genre,
            Status = model.Status,
            PagesRead = model.PagesRead,
            DateRead = model.Status == Status.Read ? model.DateRead ?? DateTime.UtcNow.Date : null,
            

        };

        // Adicionar o livro à biblioteca pessoal
        await _context.PersonalLibraries.AddAsync(libraryItem);
        await _context.SaveChangesAsync();

        // Atualiza o número de livros lidos na ReadingGoal se o status for Read
        if (model.Status == Status.Read)
        {
            var readingGoal = await _context.ReadingGoals
                .FirstOrDefaultAsync(rg => rg.UserId == userId && rg.Year == DateTime.UtcNow.Year);

            if (readingGoal != null)
            {
                readingGoal.BooksRead += 1;
                await _context.SaveChangesAsync();
            }
        }

        await _libraryService.AddBookToCachedBooksFromLibrary(userId, Isbn);
        return Ok("Livro adicionado à Biblioteca Pessoal.");
    }

    /// <summary>
    /// Updates the status of a book in the user's personal library based on the provided data transfer object.
    /// </summary>
    /// <param name="model">An object containing the updated status and the number of pages read for the book identified by its ISBN.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> representing the result of the operation. Returns a success message if the status is updated successfully,
    /// or a not found error if the book or book details are not found.
    /// </returns>
    [HttpPut("update")]
    public async Task<IActionResult> UpdateStatus([FromBody] UpdateBookStatusDto model)
    {
        int userId = _tokenService.GetUserIdByToken();

        var libraryBook = await _context.PersonalLibraries
            .FirstOrDefaultAsync(pl => pl.UserId == userId && pl.Isbn == model.Isbn);

        // Verificar se o livro existe na biblioteca
        if (libraryBook == null)
            return NotFound("Livro não encontrado na biblioteca.");

        // Obter detalhes do livro para validações
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(libraryBook.Isbn);
        if (bookDetails == null)
            return NotFound("Detalhes do livro não encontrados.");

        // Atualizar o número de páginas lidas
        libraryBook.PagesRead = (int)model.PagesRead;

        // Verificar se o número de páginas lidas alcança o total de páginas
        if (libraryBook.PagesRead >= bookDetails.Length) // Comparação automática
        {
            libraryBook.Status = Status.Read;
            libraryBook.PagesRead = (int)bookDetails.PagesRead; // Ajustar para o total de páginas
            libraryBook.DateRead = DateTime.UtcNow.Date;

            // Atualizar meta de leitura
            var readingGoal = await _context.ReadingGoals
                .FirstOrDefaultAsync(rg => rg.UserId == userId && rg.Year == DateTime.UtcNow.Year);

            if (readingGoal != null)
            {
                readingGoal.BooksRead += 1;
            }
        }
        else
        {
            // Atualizar o status com base no modelo enviado
            if (model.Status == Status.Tbr)
            {
                libraryBook.Status = Status.Tbr;
                libraryBook.DateRead = null; // Limpar a data de leitura
            }
            else if (model.Status == Status.Current_Read)
            {
                libraryBook.Status = Status.Current_Read;
            }
        }

        // Salvar alterações no banco de dados
        await _context.SaveChangesAsync();

        return Ok("Status do livro atualizado com sucesso.");
    }




    [HttpPost("reprocess-cached-books")]
    public async Task<IActionResult> ReprocessCachedBooks()
    {
        await _bookService.ReprocessCachedBooksAsync();
        return Ok("Livros reprocessados com sucesso.");
    }


    /// <summary>
    /// Retrieves a list of recommended books for the current user based on their reading history and preferences.
    /// </summary>
    /// <returns>
    /// An <see cref="IActionResult"/> containing a list of <see cref="LibraryBookDto"/> recommendations if successful.
    /// Returns a NotFound result if no recommendations are available.
    /// </returns>
    [HttpGet("recommendations")]
    public async Task<IActionResult> GetRecommendations()
    {
        int userId = _tokenService.GetUserIdByToken();
        var recommendations = await _recommendationService.GetRecommendationsForUser(userId);

        if (!recommendations.Any())
            return NotFound("Nenhuma recomendação encontrada.");

        return Ok(recommendations);
    }

    /// <summary>
    /// Retrieves the books from the user's personal library and returns a list of detailed information for each book.
    /// </summary>
    /// <returns>
    /// An <see cref="IActionResult"/> that contains a list of <see cref="LibraryBookDto"/> representing the books in the user's personal library,
    /// or an empty list if no books are present. The result includes information such as title, author, description, publish date,
    /// price, status, genre, length, pages read, percentage read, cover URL, and volume ID for each book.
    /// </returns>
    [HttpGet("list")]
    public async Task<IActionResult> ListUserLibrary()
    {
        int userId = _tokenService.GetUserIdByToken();

        var personalLibraryEntries = await _context.PersonalLibraries
            .Where(b => b.UserId == userId)
            .ToListAsync();

        var libraryBooks = new List<LibraryBookDto>();

        foreach (var entry in personalLibraryEntries)
        {
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(entry.Isbn);

            if (bookDetails != null)
            {

                float percentageRead = 0;
                if (bookDetails.Length > 0)
                {
                    percentageRead = (float)((float)entry.PagesRead / (bookDetails.Length > 0 ? bookDetails.Length : 1) * 100);
                }
                libraryBooks.Add(new LibraryBookDto
                {
                    Isbn = entry.Isbn,
                    Title = bookDetails.Title,
                    Author = bookDetails.Author,
                    Description = bookDetails.Description,
                    PublishDate = bookDetails.PublishDate,
                    Price = bookDetails.Price,
                    Status = entry.Status,
                    Genre = bookDetails.Genre,
                    Length = bookDetails.Length,
                    PagesRead = entry.PagesRead,
                    PercentageRead = percentageRead,
                    CoverUrl = bookDetails.CoverUrl,
                    VolumeId = bookDetails.VolumeId

                });
            }
        }

        return Ok(libraryBooks);
    }

    /// <summary>
    /// Retrieves a book cover image from the specified URL and returns it as a file response.
    /// </summary>
    /// <param name="imageUrl">The URL of the book cover image to be retrieved.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> containing the book cover image as a file. If the URL is invalid
    /// or the image cannot be retrieved, a corresponding error response is returned.
    /// </returns>
    [HttpGet("book-cover-proxy")]
    [AllowAnonymous] // Permite acesso a qualquer usuário, mesmo sem autenticação
    public async Task<IActionResult> GetBookCoverProxy(string imageUrl)
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
    /// Retrieves a list of books that the currently authenticated user is actively reading.
    /// </summary>
    /// <returns>
    /// An <see cref="IActionResult"/> containing either a list of <see cref="LibraryBookDto"/> objects representing the books
    /// the user is currently reading, or an error message if the user is not found or if there are no books being read at this time.
    /// </returns>
    [HttpGet("list-user-currentread-books")]
    public async Task<IActionResult> ListUserBooksCurrentRead()
    {
        var userId = _tokenService.GetUserIdByToken();

        var crBooks = await _context.PersonalLibraries
            .Where(pl => pl.UserId == userId && pl.Status == Status.Current_Read)
            .ToListAsync();

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            return NotFound("User not found");

        }


        if (!crBooks.Any())
            return NotFound("O" + user.Nome + "nao esta a ler nenhum livro de momento.");

        var crbooksdetails = new List<LibraryBookDto>();

        foreach (var entry in crBooks)
        {
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(entry.Isbn);
            if (bookDetails != null)
            {
                float percentageRead = 0;
                if (bookDetails.Length > 0)
                {
                    percentageRead = (float)((float)entry.PagesRead / (bookDetails.Length > 0 ? bookDetails.Length : 1) * 100);
                }
                crbooksdetails.Add(new LibraryBookDto
                {
                    Isbn = entry.Isbn,
                    Title = bookDetails.Title,
                    Author = bookDetails.Author,
                    Description = bookDetails.Description,
                    PublishDate = bookDetails.PublishDate,
                    Price = bookDetails.Price,
                    Status = entry.Status,
                    Genre = bookDetails.Genre,
                    Length = bookDetails.Length,
                    PagesRead = entry.PagesRead,
                    PercentageRead = percentageRead,
                    CoverUrl = bookDetails.CoverUrl,
                    VolumeId = bookDetails.VolumeId

                });

            }
        }

        return Ok(crbooksdetails);
    }

    /// <summary>
    /// Retrieves detailed information about a book using the ISBN.
    /// </summary>
    /// <param name="Isbn">The International Standard Book Number (ISBN) of the book to be retrieved. This parameter is required.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> containing the detailed information of the book if found, or a NotFound result if the book is not found
    /// in the Google Books API, or a BadRequest if the ISBN is not provided.
    /// </returns>
    [HttpGet("getBookDetails")]
    [AllowAnonymous]
    public async Task<IActionResult> GetBookDetails([FromQuery] string Isbn)
    {
        if (string.IsNullOrEmpty(Isbn)) return BadRequest("O Isbn é obrigatório.");

        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(Isbn);
        if (bookDetails == null) return NotFound("Livro não encontrado na Google Books API.");

        return Ok(bookDetails);
    }

    /// <summary>
    /// Retrieves a list of books that the user has read from their personal library.
    /// </summary>
    /// <returns>
    /// An <see cref="IActionResult"/> containing a list of books marked as 'Read' for the current user,
    /// or a NotFound result if no user is found or if no books are read.
    /// </returns>
    [HttpGet("list-user-readed-books")]
    public async Task<IActionResult> ListUserBooksReaded()
    {
        var userId = _tokenService.GetUserIdByToken();

        var readedBooks = await _context.PersonalLibraries
            .Where(pl => pl.UserId == userId && pl.Status == Status.Read)
            .ToListAsync();

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return NotFound("User not found");


        if (readedBooks == null || !readedBooks.Any())
            return NotFound("Nenhum livro lido no momento por" + user.Nome);

        var rbookdetails = new List<LibraryBookDto>();
        foreach (var entry in readedBooks)
        {
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(entry.Isbn);
            if (bookDetails != null)
            {
                float percentageRead = 0;
                if (bookDetails.Length > 0)
                    percentageRead = (float)((float)entry.PagesRead /
                        (bookDetails.Length > 0 ? bookDetails.Length : 1) * 100);
                rbookdetails.Add(new LibraryBookDto
                {
                    Isbn = entry.Isbn,
                    Title = bookDetails.Title,
                    Author = bookDetails.Author,
                    Description = bookDetails.Description,
                    PublishDate = bookDetails.PublishDate,
                    Price = bookDetails.Price,
                    Status = entry.Status,
                    Genre = bookDetails.Genre,
                    Length = bookDetails.Length,
                    PagesRead = entry.PagesRead,
                    CoverUrl = bookDetails.CoverUrl,
                    VolumeId = bookDetails.VolumeId,
                    PercentageRead = percentageRead
                });
            }
        }

        return Ok(rbookdetails);
    }

    /// <summary>
    /// Retrieves a list of books marked as 'To Be Read' (TBR) for the currently authenticated user.
    /// </summary>
    /// <returns>
    /// An <see cref="IActionResult"/> containing a list of <see cref="LibraryBookDto"/> objects representing the details of TBR books for the user.
    /// Returns a not found status if the user does not exist or if there are no TBR books.
    /// </returns>
    [HttpGet("list-user-tbr-books")]
    public async Task<IActionResult> ListUserBooksTbr()
    {
        var userId = _tokenService.GetUserIdByToken();

        var tbrBooks = await _context.PersonalLibraries
            .Where(pl => pl.UserId == userId && pl.Status == Status.Tbr)
            .ToListAsync();
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return NotFound("User not found");


        if (tbrBooks == null || !tbrBooks.Any())
            return NotFound("Nenhum livro para ler no momento por" + user.Nome);


        var tbrbooksdetails = new List<LibraryBookDto>();

        foreach (var entry in tbrBooks)
        {
            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(entry.Isbn);

            if (bookDetails != null)
                tbrbooksdetails.Add(new LibraryBookDto
                {
                    Isbn = entry.Isbn,
                    Title = bookDetails.Title,
                    Author = bookDetails.Author,
                    Description = bookDetails.Description,
                    PublishDate = bookDetails.PublishDate,
                    Price = bookDetails.Price,
                    Status = entry.Status,
                    Genre = bookDetails.Genre,
                    Length = bookDetails.Length,
                    CoverUrl = bookDetails.CoverUrl,
                    VolumeId = bookDetails.VolumeId,
                    PagesRead = 0,
                    PercentageRead = 0
                });
        }


        return Ok(tbrbooksdetails);
    }
}