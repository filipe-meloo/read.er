/**
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs.LibraryBook;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Services;

namespace Read.er.Tests;

public class PersonalLibraryTests : IDisposable
{
    private readonly PersonalLibraryController _controller;
    private readonly AppDbContext _mockContext;
    private readonly Mock<IGoogleBooksService> _mockGoogleBooksService;
    private readonly Mock<IHttpContextAccessor> _httpContextAccessorMock;
    private readonly Mock<ILibraryService> _mockLibraryService;
    private readonly TokenService _tokenService;
    private readonly int _loggedInUserId = 1;

    public PersonalLibraryTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase("PersonalLibraryTests")
            .Options;
        _mockContext = new AppDbContext(options);

        _mockGoogleBooksService = new Mock<IGoogleBooksService>();
        _mockLibraryService = new Mock<ILibraryService>();

        _httpContextAccessorMock = new Mock<IHttpContextAccessor>();
        var claims = new List<Claim> { new("userId", _loggedInUserId.ToString()) };
        var identity = new ClaimsIdentity(claims, "mock");
        var user = new ClaimsPrincipal(identity);
        var httpContext = new DefaultHttpContext { User = user };
        _httpContextAccessorMock.Setup(x => x.HttpContext).Returns(httpContext);
        _tokenService = new TokenService(_httpContextAccessorMock.Object);

        _controller = new PersonalLibraryController(
            _mockContext,
            _mockGoogleBooksService.Object,
            null,
            _mockLibraryService.Object, // Injetar o mock do LibraryService
            _tokenService
        );

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = httpContext
        };
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldReturnConflict_WhenBookAlreadyExists()
    {
        var isbn = "1234567890";
        _mockContext.PersonalLibraries.Add(new PersonalLibrary { UserId = _loggedInUserId, Isbn = isbn });
        await _mockContext.SaveChangesAsync();

        var model = new AddBookToLibraryDto { Title = "Sample Book", Status = Status.Tbr };

        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync(isbn);

        var result = await _controller.AddBookToLibrary(model);

        Assert.IsType<ConflictObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldReturnBadRequest_WhenTitleIsEmpty()
    {
        var model = new AddBookToLibraryDto { Title = "", Status = Status.Tbr };
        var result = await _controller.AddBookToLibrary(model);
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldReturnBadRequest_WhenISBNNotFound()
    {
        var model = new AddBookToLibraryDto { Title = "Unknown Book", Status = Status.Tbr };
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("ISBN não encontrado");
        var result = await _controller.AddBookToLibrary(model);
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldAddBookSuccessfully_WhenNewBook()
    {
        var model = new AddBookToLibraryDto { Title = "Crime and Punishment", Status = Status.Tbr };

        // Configuração do Mock para retornar o ISBN
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("9780140449136");

        // Configuração do Mock para retornar detalhes do livro
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn("9780140449136"))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "9780140449136",
                Title = "Crime and Punishment",
                Author = "José Meireles",
                Description = "Um livro bonito sobre a historia de um pato",
                Genre = "Ficção, Ação",
                Length = 754
            });

        // Configuração do Mock do LibraryService
        _mockLibraryService
            .Setup(service => service.AddBookToCachedBooksFromLibrary(It.IsAny<int>(), It.IsAny<string>()))
            .Returns(Task.CompletedTask);

        // Executa a ação do controlador
        var result = await _controller.AddBookToLibrary(model);

        // Verifica se o resultado é OkObjectResult
        Assert.IsType<OkObjectResult>(result);

        // Verifica se o livro foi adicionado à base de dados
        var addedBook = await _mockContext.PersonalLibraries
            .FirstOrDefaultAsync(b => b.UserId == _loggedInUserId && b.Isbn == "9780140449136");

        Assert.NotNull(addedBook);
        Assert.Equal(Status.Tbr, addedBook.Status);
    }


    [Fact]
    public async Task UpdateStatus_ShouldReturnNotFound_WhenBookNotInLibrary()
    {
        var model = new UpdateBookStatusDto { Isbn = "NonExistingISBN", PagesRead = 10 };

        // Executa a ação do controlador
        var result = await _controller.UpdateStatus(model);

        // Verifica se o resultado é NotFoundObjectResult
        Assert.IsType<NotFoundObjectResult>(result);
    }


    [Fact]
    public async Task UpdateStatus_ShouldUpdateSuccessfully_WhenBookExists()
    {
        var book = new PersonalLibrary { UserId = _loggedInUserId, Isbn = "9780140449136", Status = Status.Tbr };
        await _mockContext.PersonalLibraries.AddAsync(book);
        await _mockContext.SaveChangesAsync();

        var model = new UpdateBookStatusDto { Isbn = "9780140449136", PagesRead = 754 };

        // Configuração do Mock para retornar detalhes do livro
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn("9780140449136"))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "9780140449136",
                Length = 754,
                PagesRead = 0
            });

        // Executa a ação do controlador
        var result = await _controller.UpdateStatus(model);

        // Verifica se o resultado é OkObjectResult
        Assert.IsType<OkObjectResult>(result);

        // Verifica se o status do livro foi atualizado
        var updatedBook = await _mockContext.PersonalLibraries
            .FirstOrDefaultAsync(b => b.UserId == _loggedInUserId && b.Isbn == "9780140449136");
        Assert.NotNull(updatedBook);
        Assert.Equal(Status.Read, updatedBook.Status);
    }


    [Fact]
    public async Task ListUserLibrary_ShouldReturnEmptyList_WhenNoBooksInLibrary()
    {
        var result = await _controller.ListUserLibrary();
        var okResult = Assert.IsType<OkObjectResult>(result);
        var books = Assert.IsAssignableFrom<List<LibraryBookDto>>(okResult.Value);
        Assert.Empty(books);
    }

    [Fact]
    public async Task ListUserLibrary_ShouldReturnBooks_WhenBooksExistInLibrary()
    {
        var book = new PersonalLibrary { UserId = _loggedInUserId, Isbn = "1234567890", Status = Status.Tbr };
        await _mockContext.PersonalLibraries.AddAsync(book);
        await _mockContext.SaveChangesAsync();

        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn(It.IsAny<string>()))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "1234567890",
                Title = "Sample Title",
                Author = "Sample Author",
                Description = "Sample Description",
                PublishDate = DateTime.Parse("2024-11-03"),
                Price = 19.99M,
                Status = Status.Tbr
            });

        var result = await _controller.ListUserLibrary();
        var okResult = Assert.IsType<OkObjectResult>(result);
        var books = Assert.IsAssignableFrom<List<LibraryBookDto>>(okResult.Value);
        Assert.Single(books);
        Assert.Equal("1234567890", books[0].Isbn);
        Assert.Equal("Sample Title", books[0].Title);
    }

    public void Dispose()
    {
        _mockContext.Database.EnsureDeleted();
        _mockContext.Dispose();
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldReturnBadRequest_WhenISBNTooShort()
    {
        var model = new AddBookToLibraryDto { Title = "Short ISBN Book", Status = Status.Tbr };
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("123");
        var result = await _controller.AddBookToLibrary(model);
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldReturnBadRequest_WhenISBNTooLong()
    {
        var model = new AddBookToLibraryDto { Title = "Long ISBN Book", Status = Status.Tbr };
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("12345678901234");
        var result = await _controller.AddBookToLibrary(model);
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldAddBookSuccessfully_WhenISBNIs10Characters()
    {
        var model = new AddBookToLibraryDto
        {
            Title = "Book with 10 ISBN",
            Status = Status.Tbr, 
            PagesRead = 0
        };

        // Configuração do Mock para retornar o ISBN
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("1234567890");

        // Configuração do Mock para retornar detalhes do livro
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn("1234567890"))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "1234567890",
                Title = "Book with 10 ISBN",
                Author = "Author de 10 ISBN",
                Description = "Uma bela descricao sobre um livro que tem um ISBN com 10 caracteres",
                Genre = "Desconhecido",
                Length = 300
            });

        // Configuração do Mock do LibraryService
        _mockLibraryService
            .Setup(service => service.AddBookToCachedBooksFromLibrary(It.IsAny<int>(), It.IsAny<string>()))
            .Returns(Task.CompletedTask);

        // Executa a ação do controlador
        var result = await _controller.AddBookToLibrary(model);

        // Verifica se o resultado é OkObjectResult
        Assert.IsType<OkObjectResult>(result);
    }

    [Fact]
    public async Task AddBookToLibrary_ShouldAddBookSuccessfully_WhenISBNIs13Characters()
    {
        var model = new AddBookToLibraryDto { Title = "Book with 13 ISBN", Status = Status.Tbr, PagesRead = 0 };

        // Configuração do Mock para retornar o ISBN
        _mockGoogleBooksService.Setup(service => service.GetIsbnByTitle(It.IsAny<string>()))
            .ReturnsAsync("9781234567897");

        // Configuração do Mock para retornar detalhes do livro
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn("9781234567897"))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "9781234567897",
                Title = "Book with 13 ISBN",
                Author = "Author dos 13 caracteres",
                Description = "Já nao gosto muito deste tipo de livros, não me perguntem porquê?",
                Genre = "Aborrecido",
                Length = 400
            });

        // Configuração do Mock do LibraryService
        _mockLibraryService
            .Setup(service => service.AddBookToCachedBooksFromLibrary(It.IsAny<int>(), It.IsAny<string>()))
            .Returns(Task.CompletedTask);

        // Executa a ação do controlador
        var result = await _controller.AddBookToLibrary(model);

        // Verifica se o resultado é OkObjectResult
        Assert.IsType<OkObjectResult>(result);
    }


    [Fact]
    public async Task ListUserLibrary_ShouldIncludeGenre_WhenBooksHaveGenre()
    {
        // Arrange
        var book = new PersonalLibrary { UserId = _loggedInUserId, Isbn = "1234567890", Status = Status.Tbr };
        await _mockContext.PersonalLibraries.AddAsync(book);
        await _mockContext.SaveChangesAsync();

        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn(It.IsAny<string>()))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = "1234567890",
                Title = "Sample Title",
                Author = "Sample Author",
                Description = "Sample Description",
                PublishDate = DateTime.Parse("2024-11-03"),
                Price = 19.99M,
                Status = Status.Tbr,
                Genre = "Fiction, Adventure"
            });

        // Act
        var result = await _controller.ListUserLibrary();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var books = Assert.IsAssignableFrom<List<LibraryBookDto>>(okResult.Value);
        Assert.Single(books);
        Assert.Equal("Fiction, Adventure", books[0].Genre);
    }

    [Fact]
    public async Task GetBookDetails_ShouldReturnBookDetails_WhenISBNIsValid()
    {
        // Arrange
        var isbn = "1234567890";
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn(isbn))
            .ReturnsAsync(new LibraryBookDto
            {
                Isbn = isbn,
                Title = "Sample Title",
                Author = "Sample Author",
                Description = "Sample Description",
                PublishDate = DateTime.Parse("2024-11-03"),
                Price = 19.99M,
                Status = Status.Tbr,
                Genre = "Fiction, Adventure"
            });

        // Act
        var result = await _controller.GetBookDetails(isbn);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        var bookDetails = Assert.IsType<LibraryBookDto>(okResult.Value);
        Assert.Equal(isbn, bookDetails.Isbn);
        Assert.Equal("Sample Title", bookDetails.Title);
        Assert.Equal("Fiction, Adventure", bookDetails.Genre);
    }

    [Fact]
    public async Task GetBookDetails_ShouldReturnNotFound_WhenISBNIsInvalid()
    {
        // Arrange
        var isbn = "InvalidISBN";
        _mockGoogleBooksService.Setup(service => service.FetchBookDetailsByIsbn(isbn))
            .ReturnsAsync((LibraryBookDto)null);

        // Act
        var result = await _controller.GetBookDetails(isbn);

        // Assert
        Assert.IsType<NotFoundObjectResult>(result);
    }
}
*/