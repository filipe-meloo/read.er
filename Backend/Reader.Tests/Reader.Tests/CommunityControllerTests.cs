using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Moq;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs.Community;
using Read.er.Enumeracoes;
using Read.er.Models;
using Read.er.Models.Communities;
using Read.er.Models.Users;
using Read.er.Services;
/**
public class CommunityControllerTests
{
    private DbContextOptions<AppDbContext> CreateNewContextOptions()
    {
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
    }

    public class StubGoogleBooksService : GoogleBooksService
    {
        public StubGoogleBooksService(IConfiguration configuration) : base(configuration)
        {
        }
    }

    /**
    private CommunityController CreateControllerWithUserClaims(AppDbContext context, int userId)
    {
        var configurationMock = new Mock<IConfiguration>();
        configurationMock.Setup(config => config["GoogleBooksApi:ApiKey"]).Returns("fake-api-key");
        var googleBooksService = new StubGoogleBooksService(configurationMock.Object);

        // Mock para o TokenService
        var httpContextAccessorMock = new Mock<IHttpContextAccessor>();
        var claims = new List<Claim> { new("userId", userId.ToString()) };
        var identity = new ClaimsIdentity(claims);
        var user = new ClaimsPrincipal(identity);
        var httpContext = new DefaultHttpContext { User = user };
        httpContextAccessorMock.Setup(x => x.HttpContext).Returns(httpContext);

        var tokenService = new TokenService(httpContextAccessorMock.Object);

        var controller = new CommunityController(context, tokenService);
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        return controller;
    }
    

    private async Task AddLeitorUserAsync(AppDbContext context, int userId, string username)
    {
        var user = new User
        {
            Id = userId,
            Username = username,
            Email = $"{username.ToLower()}@example.com",
            Nome = "User " + username,
            Password = "password123",
            Role = Role.Leitor,
            Bio = "Test bio"
        };
        await context.Users.AddAsync(user);
        await context.SaveChangesAsync();
    }

    [Fact]
    public async Task CreateCommunity_SuccessfullyCreatesCommunity()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddLeitorUserAsync(context, 1, "LeitorUser1");
            var controller = CreateControllerWithUserClaims(context, 1);

            var model = new CreateCommunityDto
            {
                CommunityName = "Test Community",
                CommunityDescritpion = "A community for testing."
            };

            var result = await controller.CreateCommunity(model);

            Assert.IsType<OkObjectResult>(result);
            var community = await context.Communities.FirstOrDefaultAsync();
            Assert.NotNull(community);
            Assert.Equal("Test Community", community.Name);
            Assert.Equal(1, community.AdminId);
        }
    }

    [Fact]
    public async Task JoinCommunityRequest_UserCanRequestToJoinCommunity()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddLeitorUserAsync(context, 2, "LeitorUser2");
            var controller = CreateControllerWithUserClaims(context, 2);

            var community = new Community
            {
                Id = 1,
                Name = "Test Community",
                AdminId = 1,
                Description = "Test Community Description"
            };
            await context.Communities.AddAsync(community);
            await context.SaveChangesAsync();

            var result = await controller.JoinCommunityRequest(1, CommunityRole.Member);

            Assert.IsType<OkObjectResult>(result);
            var userCommunity =
                await context.UserCommunity.FirstOrDefaultAsync(uc =>
                    uc.UserId == 2 && uc.CommunityId == community.Id);
            Assert.NotNull(userCommunity);
            Assert.True(userCommunity.IsPending);
            Assert.Equal(CommunityRole.Member, userCommunity.Role);
        }
    }

    [Fact]
    public async Task CreateCommunity_WithEmptyName_ReturnsBadRequest()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddLeitorUserAsync(context, 1, "LeitorUser1");
            var controller = CreateControllerWithUserClaims(context, 1);

            var model = new CreateCommunityDto
            {
                CommunityName = "",
                CommunityDescritpion = "A valid description."
            };

            var result = await controller.CreateCommunity(model);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }

    [Fact]
    public async Task CreateCommunity_WithDescriptionExceedingMaxLength_ReturnsBadRequest()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddLeitorUserAsync(context, 1, "LeitorUser1");
            var controller = CreateControllerWithUserClaims(context, 1);

            var model = new CreateCommunityDto
            {
                CommunityName = "Valid Community",
                CommunityDescritpion = new string('A', 256)
            };

            var result = await controller.CreateCommunity(model);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }

    [Fact]
    public async Task CreateCommunity_ShouldReturnForbid_WhenUserIsNotLeitor()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var user = new User
            {
                Id = 1,
                Username = "AdminUser",
                Email = "admin@example.com",
                Nome = "Admin",
                Password = "password123",
                Role = Role.Admin,
                Bio = "Test Bio"
            };
            await context.Users.AddAsync(user);
            await context.SaveChangesAsync();

            var controller = CreateControllerWithUserClaims(context, 1);
            var model = new CreateCommunityDto
            {
                CommunityName = "Test Community",
                CommunityDescritpion = "A community for testing."
            };

            var result = await controller.CreateCommunity(model);

            Assert.IsType<ForbidResult>(result);
        }
    }
}
*/