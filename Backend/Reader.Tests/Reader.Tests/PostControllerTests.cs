using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes;
using Read.er.Enumeracoes.Post;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Posts;
using Read.er.Models.Users;
using Read.er.Services;

public class PostControllerTests
{
    private DbContextOptions<AppDbContext> CreateNewContextOptions()
    {
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
    }

    private PostController CreateControllerWithUserClaims(AppDbContext context, int userId,
        IGoogleBooksService googleBooksService)
    {
        var mockWsManager = new Mock<WsManager>(new HttpClient());
        var notificationService = new NotificationService(context, googleBooksService, mockWsManager.Object);

        var controller = new PostController(context, googleBooksService, notificationService);
        var claims = new List<Claim> { new("userId", userId.ToString()) };
        var identity = new ClaimsIdentity(claims);
        var user = new ClaimsPrincipal(identity);

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };

        return controller;
    }

    [Fact]
    public async Task CreatePost_SuccessfullyCreatesPost_WithBookTitle()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var googleBooksServiceMock = new Mock<IGoogleBooksService>();
            googleBooksServiceMock.Setup(s => s.GetIsbnByTitle(It.IsAny<string>())).ReturnsAsync("1234567890123");

            var controller = CreateControllerWithUserClaims(context, 1, googleBooksServiceMock.Object);

            var user = new User
            {
                Id = 1,
                Username = "TestUser",
                Email = "testuser@example.com",
                Nome = "Test User",
                Password = "password123",
                Bio = "Test Bio"
            };
            await context.Users.AddAsync(user);
            await context.SaveChangesAsync();

            var createPostDto = new CreatePostDto
            {
                Conteudo = "Este é um post de teste",
                TipoPublicacao = TipoPublicacao.Citacao,
                TituloLivro = "Um Livro Qualquer"
            };

            var result = await controller.CreatePost(createPostDto);

            Assert.IsType<OkObjectResult>(result);
            var post = await context.Posts.FirstOrDefaultAsync();
            Assert.NotNull(post);
            Assert.Equal("Este é um post de teste", post.Conteudo);
            Assert.Equal(TipoPublicacao.Citacao, post.TipoPublicacao);
        }
    }

    [Fact]
    public async Task ReactToPost_AddsOrUpdatesReaction()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var googleBooksServiceMock = new Mock<IGoogleBooksService>();
            var controller = CreateControllerWithUserClaims(context, 1, googleBooksServiceMock.Object);

            var user = new User
            {
                Id = 1,
                Username = "TestUser",
                Email = "testuser@example.com",
                Nome = "Test User",
                Password = "password123",
                Bio = "Test Bio"
            };

            var post = new Post
            {
                Id = 1,
                Conteudo = "Este é um post",
                IdUser = 2,
                Isbn = "1234567890",
                BookTitle = "Livro Teste"
            };

            await context.Users.AddAsync(user);
            await context.Posts.AddAsync(post);
            await context.SaveChangesAsync();

            var result = await controller.ReactToPost(1, ReactionType.Like);

            Assert.IsType<OkObjectResult>(result);
            var reaction = await context.PostReactions.FirstOrDefaultAsync();
            Assert.NotNull(reaction);
            Assert.Equal(ReactionType.Like, reaction.ReactionType);
        }
    }


    [Fact]
    public async Task SharePost_FailsIfPostIsAlreadyAShare()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var googleBooksServiceMock = new Mock<IGoogleBooksService>();
            var controller = CreateControllerWithUserClaims(context, 1, googleBooksServiceMock.Object);

            var user = new User
            {
                Id = 1,
                Username = "TestUser",
                Email = "testuser@example.com",
                Nome = "Test User",
                Password = "password123",
                Bio = "Test Bio"
            };

            var originalPost = new Post
            {
                Id = 1,
                Conteudo = "Post original",
                IdUser = 2,
                Isbn = "1234567890",
                BookTitle = "Livro Teste"
            };
            var sharedPost = new Post
            {
                Id = 2,
                Conteudo = "Post partilhado",
                OriginalPostId = 1,
                IdUser = 1,
                Isbn = "1234567890",
                BookTitle = "Livro Teste"
            };

            await context.Users.AddAsync(user);
            await context.Posts.AddRangeAsync(originalPost, sharedPost);
            await context.SaveChangesAsync();

            var result = await controller.SharePost(2);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }

    [Fact]
    public async Task CreatePost_ShouldReturnBadRequest_WhenContentTooLong()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var googleBooksServiceMock = new Mock<IGoogleBooksService>();
            var controller = CreateControllerWithUserClaims(context, 1, googleBooksServiceMock.Object);

            var createPostDto = new CreatePostDto
            {
                Conteudo = new string('A', 1001),
                TipoPublicacao = TipoPublicacao.Critica,
                TituloLivro = "Um Livro Qualquer"
            };

            var result = await controller.CreatePost(createPostDto);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }

    [Fact]
    public async Task ReportPost_SuccessfullyReportsPost()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var googleBooksServiceMock = new Mock<IGoogleBooksService>();
            var controller = CreateControllerWithUserClaims(context, 1, googleBooksServiceMock.Object);

            var post = new Post
            {
                Id = 1,
                Conteudo = "Este é um post",
                IdUser = 2,
                Isbn = "1234567890",
                BookTitle = "Livro Teste"
            };

            await context.Posts.AddAsync(post);
            await context.SaveChangesAsync();

            var result = await controller.ReportPost(1);

            Assert.IsType<OkObjectResult>(result);
            var reportedPost = await context.Posts.FirstOrDefaultAsync(p => p.Id == 1);
            Assert.True(reportedPost.IsReported);
        }
    }
}