using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Models;
using Read.er.Models.Users;
using Read.er.Services;

public class AuthControllerTests
{
    private readonly AuthController _controller;
    private readonly AppDbContext _context;


    public AuthControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase("TestDb")
            .Options;
        _context = new AppDbContext(options);

        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string>
            {
                { "Jwt:Key", "quesegredoincrivelmeusamigosquevaopassaralds" }
            })
            .Build();

        _controller = new AuthController(_context, configuration);
    }


    //LOGIN TESTING
    [Fact]
    public async Task Login_ShouldReturnOk_WithCorrectCredentials()
    {
        var passwordHasher = new PasswordHasher();
        var user = new User
        {
            Email = "user2@example.com",
            Password = passwordHasher.HashPassword("string"),
            Nome = "string",
            Username = "ruixpto",
            Bio = "Test Bio"
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var loginModel = new LoginModel
        {
            Email = "user2@example.com",
            Password = "string"
        };

        var result = await _controller.Login(loginModel);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var tokenResponse = okResult.Value as LoginResponse;

        Assert.NotNull(tokenResponse);
        Assert.False(string.IsNullOrEmpty(tokenResponse.Token), "Token está vazio ou nulo.");
    }


    [Fact]
    public async Task Login_ShouldReturnUnauthorized_WithIncorrectPassword()
    {
        var passwordHasher = new PasswordHasher();
        var user = new User
        {
            Email = "wrongpassworduser@example.com",
            Password = passwordHasher.HashPassword("password123"),
            Nome = "User With Wrong Password",
            Username = "wrongpassworduser",
            Bio = "Test Bio"
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var loginModel = new LoginModel
        {
            Email = "wrongpassworduser@example.com",
            Password = "wrongpassword"
        };


        var result = await _controller.Login(loginModel);

        Assert.IsType<UnauthorizedResult>(result);
    }

    [Fact]
    public async Task Login_ShouldReturnBadRequest_WithMissingEmail()
    {
        var loginModel = new LoginModel
        {
            Password = "password123"
        };

        var result = await _controller.Login(loginModel);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Login_ShouldReturnBadRequest_WithMissingPassword()
    {
        var loginModel = new LoginModel
        {
            Email = "testuser@example.com"
        };

        var result = await _controller.Login(loginModel);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    //REGISTRATION TESTING

    [Fact]
    public async Task Register_ShouldReturnOk_WhenRegistrationIsSuccessful()
    {
        var newUser = new CreateUserDto
        {
            Email = "newuser@example.com",
            Password = "password123",
            Nome = "New User",
            Username = "newuser123",
            Nascimento = new DateOnly(1990, 1, 1),
            Bio = "Test bio"
        };


        var result = await _controller.Registo(newUser);


        var okResult = Assert.IsType<OkObjectResult>(result);
        var registeredUser = okResult.Value as User;
        Assert.NotNull(registeredUser);
        Assert.Equal("newuser@example.com", registeredUser.Email);
    }

    [Fact]
    public async Task Register_ShouldReturnBadRequest_WhenEmailIsAlreadyInUse()
    {
        var existingUser = new User
        {
            Email = "duplicate@example.com",
            Password = new PasswordHasher().HashPassword("password123"),
            Nome = "Existing User",
            Username = "existinguser",
            Nascimento = new DateOnly(1990, 1, 1),
            Bio = "Test bio"
        };
        _context.Users.Add(existingUser);
        await _context.SaveChangesAsync();

        var duplicateUser = new CreateUserDto
        {
            Email = "duplicate@example.com",
            Password = "password123",
            Nome = "Duplicate User",
            Username = "duplicateuser",
            Nascimento = new DateOnly(1990, 1, 1)
        };

        var result = await _controller.Registo(duplicateUser);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal("Email já está em uso.", badRequestResult.Value);
    }


    [Fact]
    public void Logout_ShouldReturnOk_WithSuccessMessage()
    {
        var result = _controller.Logout();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("Logout realizado com sucesso.", okResult.Value);
    }
}