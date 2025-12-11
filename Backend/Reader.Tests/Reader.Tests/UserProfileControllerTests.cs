/**
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Users;

public class UserProfileControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly UserProfileController _controller;
    private readonly Mock<ITokenService> _mockTokenService;

    public UserProfileControllerTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        _context = new AppDbContext(options);
        _mockTokenService = new Mock<ITokenService>();
        _controller = new UserProfileController(_context, _mockTokenService.Object);
    }

    [Fact]
    public async Task UpdateProfile_ShouldReturnOk_WhenProfileIsUpdatedSuccessfully()
    {
        // Arrange
        var user = new User
        {
            Id = 1,
            Username = "testuser",
            Email = "test@example.com",
            Nome = "Test User",
            Nascimento = new DateOnly(1990, 1, 1),
            Password = "hashed_password123"
        };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var dto = new UpdateProfileDTO
        {
            Username = "updateduser",
            Email = "updated@example.com",
            Nome = "Updated User",
            Nascimento = new DateOnly(1991, 2, 2)
        };

        // Act
        var result = await _controller.UpdateProfile(1, dto);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);


        var responseContent = okResult.Value as Dictionary<string, object>;


        Assert.NotNull(responseContent);
        Assert.Equal("Profile updated successfully!", responseContent["message"]);


        var updatedUser = await _context.Users.FindAsync(1);
        Assert.Equal("updateduser", updatedUser.Username);
        Assert.Equal("updated@example.com", updatedUser.Email);
        Assert.Equal("Updated User", updatedUser.Nome);
        Assert.Equal(new DateOnly(1991, 2, 2), updatedUser.Nascimento);
    }

    [Fact]
    public async Task UpdateProfile_ShouldReturnNotFound_WhenUserDoesNotExist()
    {
        // Arrange
        var dto = new UpdateProfileDTO
        {
            Username = "nonexistentuser",
            Email = "nonexistent@example.com",
            Nome = "Nonexistent User",
            Nascimento = new DateOnly(1995, 3, 3)
        };

        // Act
        var result = await _controller.UpdateProfile(999, dto);

        // Assert
        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result);


        Assert.Equal("User not found", notFoundResult.Value?.ToString());
    }


    [Fact]
    public async Task UpdateProfile_ShouldReturnBadRequest_WhenModelIsInvalid()
    {
        // Arrange
        var dto = new UpdateProfileDTO
        {
            Username = "",
            Email = "invalidemail.com",
            Nome = "Invalid User",
            Nascimento = new DateOnly(1995, 3, 3)
        };
        _controller.ModelState.AddModelError("Email", "Invalid email format");

        // Act
        var result = await _controller.UpdateProfile(1, dto);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
    }


    public void Dispose()
    {
        _context.Dispose();
    }

    //ECP E BVA


    [Fact]
    public async Task UpdateProfile_ShouldReturnBadRequest_WhenUsernameExceedsMaxLength()
    {
        // Arrange
        var user = new User
        {
            Id = 2,
            Username = "validuser",
            Email = "valid@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1),
            Password = "hashed_password123"
        };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var dto = new UpdateProfileDTO
        {
            Username = new string('a', 51),
            Email = "valid@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1)
        };

        // Act
        var result = await _controller.UpdateProfile(user.Id, dto);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task UpdateProfile_ShouldReturnBadRequest_WhenEmailExceedsMaxLength()
    {
        // Arrange
        var user = new User
        {
            Id = 3,
            Username = "validuser",
            Email = "valid@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1),
            Password = "hashed_password123"
        };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var dto = new UpdateProfileDTO
        {
            Username = "validuser",
            Email = new string('a', 246) + "@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1)
        };

        // Act
        var result = await _controller.UpdateProfile(user.Id, dto);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task UpdateProfile_ShouldReturnBadRequest_WhenUsernameIsEmpty()
    {
        // Arrange
        var user = new User
        {
            Id = 4,
            Username = "validuser",
            Email = "valid@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1),
            Password = "hashed_password123"
        };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var dto = new UpdateProfileDTO
        {
            Username = "",
            Email = "valid@example.com",
            Nome = "Valid User",
            Nascimento = new DateOnly(1990, 1, 1)
        };

        // Act
        var result = await _controller.UpdateProfile(user.Id, dto);

        // Assert
        Assert.IsType<BadRequestObjectResult>(result);
    }
}
*/