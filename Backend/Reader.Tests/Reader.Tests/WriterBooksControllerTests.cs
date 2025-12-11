using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs.LibraryBook;
using Read.er.DTOs.WriterBooks;
using Read.er.Enumeracoes.Books;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Book;
using Read.er.Models.SaleTrades;
using Read.er.Services;

public class WriterBooksControllerTests : IDisposable
{
    private readonly WriterBooksController _controller;
    private readonly AppDbContext _context;
    private readonly Mock<IGoogleBooksService> _googleBooksServiceMock;
    private readonly Mock<IHttpContextAccessor> _httpContextAccessorMock;
    private readonly TokenService _tokenService;
    private readonly IOptions<StripeSettings> _stripeSettings;

    public WriterBooksControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        _context = new AppDbContext(options);
        _googleBooksServiceMock = new Mock<IGoogleBooksService>();


        // Simulação do IHttpContextAccessor
        _httpContextAccessorMock = new Mock<IHttpContextAccessor>();
        var claims = new List<Claim> { new("userId", "1") };
        var identity = new ClaimsIdentity(claims);
        var user = new ClaimsPrincipal(identity);
        var httpContext = new DefaultHttpContext { User = user };
        _httpContextAccessorMock.Setup(_ => _.HttpContext).Returns(httpContext);

        _tokenService = new TokenService(_httpContextAccessorMock.Object);

        _stripeSettings = Options.Create(new StripeSettings { SecretKey = "test_secret_key" });

        _controller =
            new WriterBooksController(_context, _googleBooksServiceMock.Object, _stripeSettings, _tokenService);
    }

    [Fact]
    public async Task AddWriterBook_AddsBookSuccessfully()
    {
        var dto = new AddWriterBookDto { ISBN = "9780140449136", Price = 10.99M };
        _googleBooksServiceMock.Setup(g => g.FetchBookDetailsByIsbn(dto.ISBN))
            .ReturnsAsync(new LibraryBookDto
            {
                Title = "Book Title",
                Author = "Book Author",
                Description = "Book Description",
                PublishDate = DateTime.Now.AddYears(-1),
                Price = dto.Price
            });

        var result = await _controller.AddWriterBook(dto);
        Assert.IsType<OkObjectResult>(result);
        //Assert.Single(_context.WriterBooks);
        var book = await _context.WriterBooks.FirstOrDefaultAsync();
        Assert.Equal("Book Title", book.Title);
        Assert.Equal(WriterBookStatus.Pending, book.Status);
    }

    [Fact]
    public async Task AddWriterBook_ReturnsConflict_WhenBookAlreadyExists()
    {
        var dto = new AddWriterBookDto { ISBN = "9780140449136", Price = 10.99M };
        _context.WriterBooks.Add(new WriterBook
        {
            Isbn = dto.ISBN,
            WriterId = 1,
            Title = "Existing Book",
            Author = "Author",
            Description = "Description"
        });
        await _context.SaveChangesAsync();

        var result = await _controller.AddWriterBook(dto);

        Assert.IsType<ConflictObjectResult>(result);
    }

    [Fact]
    public async Task EditWriterBook_UpdatesBookSuccessfully()
    {
        var book = new WriterBook
        {
            Id = 1,
            WriterId = 1,
            Isbn = "9780140449136",
            Title = "Old Title",
            Author = "Old Author",
            Description = "Old Description",
            PublishDate = DateTime.Now.AddYears(-5),
            Price = 15.99M
        };
        _context.WriterBooks.Add(book);
        await _context.SaveChangesAsync();

        var dto = new EditWriterBookDto
        {
            Title = "New Title",
            Author = "New Author",
            Description = "New Description"
        };

        var result = await _controller.EditWriterBook(book.Id, dto);

        Assert.IsType<OkObjectResult>(result);
        var updatedBook = await _context.WriterBooks.FindAsync(book.Id);
        Assert.Equal("New Title", updatedBook.Title);
        Assert.Equal("New Author", updatedBook.Author);
        Assert.Equal("New Description", updatedBook.Description);
    }

    [Fact]
    public async Task RemoveWriterBook_RemovesBookSuccessfully()
    {
        var book = new WriterBook
        {
            Id = 2,
            WriterId = 1,
            Isbn = "9780140449136",
            Title = "Sample Book",
            Author = "Sample Author",
            Description = "Sample Description",
            Status = WriterBookStatus.Pending
        };

        _context.WriterBooks.Add(book);
        await _context.SaveChangesAsync();

        var result = await _controller.RemoveWriterBook(book.Id);

        Assert.IsType<OkObjectResult>(result);
        Assert.Null(await _context.WriterBooks.FindAsync(book.Id));
    }

    [Fact]
    public async Task ListApprovedBooks_ReturnsApprovedBooks()
    {
        // Configura o mock para GoogleBooksService
        _googleBooksServiceMock
       .Setup(service => service.FetchBookDetailsByIsbn(It.IsAny<string>()))
       .ReturnsAsync(new LibraryBookDto
       {
           Title = "Livro Mock",
           Author = "Autor Mock",
           CoverUrl = "http://mock.cover.url",
           VolumeId = "mockVolumeId"
       });

        var mockTokenService = new Mock<ITokenService>();
        mockTokenService.Setup(service => service.GetUserIdByToken()).Returns(1);
        
        // Cria um controlador com o mock configurado
        var controller = new WriterBooksController(_context, _googleBooksServiceMock.Object, Options.Create(new StripeSettings { SecretKey = "test" }), mockTokenService.Object);

        // Adiciona dados de teste
        _context.WriterBooks.Add(new WriterBook
        {
            Isbn = "123",
            Status = WriterBookStatus.Approved,
            WriterId = 1,
            Title = "Title1",
            Author = "Author1",
            Description = "Desc1"
        });
        _context.WriterBooks.Add(new WriterBook
        {
            Isbn = "456",
            Status = WriterBookStatus.Pending,
            WriterId = 1,
            Title = "Title2",
            Author = "Author2",
            Description = "Desc2"
        });
        await _context.SaveChangesAsync();

        // Executa o método a ser testado
        var result = await controller.ListApprovedBooks();

        // Verifica o resultado
        var okResult = Assert.IsType<OkObjectResult>(result);
        var approvedBooks = Assert.IsType<List<BookDetailsDto>>(okResult.Value);
        Assert.Single(approvedBooks);
        Assert.Equal(1, approvedBooks.First().Id);
    }

    [Fact]
    public async Task GetBookStatus_ReturnsStatusForOwnBook()
    {
        var book = new WriterBook
        {
            WriterId = 1,
            Isbn = "9780140449136",
            Title = "Sample Book",
            Author = "Sample Author",
            Description = "Sample Description",
            Status = WriterBookStatus.Pending
        };

        await _context.WriterBooks.AddAsync(book);
        await _context.SaveChangesAsync();

        var result = await _controller.GetBookStatus(book.Id);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(WriterBookStatus.Pending, okResult.Value);
    }

    [Fact]
    public async Task GetBookStatus_ReturnsUnauthorized_ForAnotherUsersBook()
    {
        var book = new WriterBook
        {
            Id = 1,
            WriterId = 2,
            Isbn = "9780140449136",
            Title = "Sample Book",
            Author = "Sample Author",
            Description = "Sample Description",
            Status = WriterBookStatus.Pending
        };
        _context.WriterBooks.Add(book);
        await _context.SaveChangesAsync();

        var result = await _controller.GetBookStatus(book.Id);

        Assert.IsType<UnauthorizedObjectResult>(result);
    }

    [Fact]
    public async Task AddWriterBook_ShouldReturnBadRequest_WhenISBNTooLong()
    {
        var dto = new AddWriterBookDto { ISBN = new string('1', 14), Price = 10.99M };

        var result = await _controller.AddWriterBook(dto);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task EditWriterBook_ShouldReturnBadRequest_WhenTitleIsEmpty()
    {
        var book = new WriterBook
        {
            WriterId = 1,
            Isbn = "9780140449136",
            Title = "Old Title",
            Author = "Old Author",
            Description = "Old Description"
        };
        await _context.WriterBooks.AddAsync(book);
        await _context.SaveChangesAsync();

        var dto = new EditWriterBookDto { Title = "", Author = "New Author", Description = "New Description" };

        var result = await _controller.EditWriterBook(book.Id, dto);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }
}