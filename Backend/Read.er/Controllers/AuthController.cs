using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Models.Communities;
using Read.er.Models.Posts;
using Read.er.Models.Users;
using Read.er.Services;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly PasswordHasher _passwordHasher;

    public AuthController(AppDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
        _passwordHasher = new PasswordHasher();
    }

    /// <summary>
    /// Handles user registration by creating a new user account based on provided details.
    /// </summary>
    /// <param name="dto">A data transfer object containing the details required for user registration.</param>
    /// <returns>
    /// Returns a response indicating the result of the registration process. If successful, returns an Ok result with user details.
    /// If the registration fails due to validation errors or if the email is already in use, returns a BadRequest result with error details.
    /// </returns>
    [HttpPost("registo")]
    public async Task<IActionResult> Registo([FromBody] CreateUserDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Username))
            ModelState.AddModelError("Username", "O campo 'Username' é obrigatório.");
        if (string.IsNullOrWhiteSpace(dto.Email))
            ModelState.AddModelError("Email", "O campo 'Email' é obrigatório.");
        if (string.IsNullOrWhiteSpace(dto.Password))
            ModelState.AddModelError("Password", "O campo 'Password' é obrigatório.");
        if (dto.Nascimento == default)
            ModelState.AddModelError("Nascimento", "O campo 'Nascimento' é obrigatório.");
        if (!ModelState.IsValid) return BadRequest(ModelState);

        if (await _context.Users.AnyAsync(u => u.Email == dto.Email)) return BadRequest("Email já está em uso.");

        var user = new User
        {
            Username = dto.Username,
            Email = dto.Email,
            Password = _passwordHasher.HashPassword(dto.Password),
            Role = dto.Role,
            Nome = dto.Nome,
            Nascimento = dto.Nascimento,
            Bio = dto.Bio,
            Posts = new List<Post>(),
            SentFriendRequests = new List<UserFriendship>(),
            ReceivedFriendRequests = new List<UserFriendship>(),
            Following = new List<FollowAuthors>(),
            Followers = new List<FollowAuthors>(),
            UserCommunities = new List<UserCommunity>()
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(user);
    }

    /// <summary>
    /// Retrieves the logged-in user's ID from their authentication token.
    /// </summary>
    /// <returns>
    /// Returns an Ok result containing the user ID if the token is valid and contains the user ID claim.
    /// If the token is invalid or does not contain the user ID, returns an Unauthorized result.
    /// In the event of an error while processing the token, returns a server error result with error details.
    /// </returns>
    [HttpGet("me")]
    [Authorize]
    public IActionResult GetLoggedUserId()
    {
        try
        {
            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == "userId");

            if (userIdClaim == null) return Unauthorized("Token inválido ou não contém o ID do utilizador.");

            var userId = userIdClaim.Value;
            return Ok(new { UserId = userId });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "Erro ao processar o token.", Details = ex.Message });
        }
    }

    /// <summary>
    /// Retrieves the role of the currently logged-in user from the JWT token claims.
    /// </summary>
    /// <returns>
    /// Returns an Ok result containing the user's role if the claim is found in the token.
    /// If the role claim is absent or the token is invalid, returns an Unauthorized result indicating an issue with the token.
    /// In case of a processing error, returns a status code 500 with error details.
    /// </returns>
    [HttpGet("myRole")]
    [Authorize]
    public IActionResult GetLoggedUserRole()
    {
        try
        {
            // Recupera o claim do Role no token JWT
            var roleClaim = User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Role);

            if (roleClaim == null) return Unauthorized("Token inválido ou não contém o papel do utilizador.");

            // Retorna o papel do utilizador
            var role = roleClaim.Value;
            return Ok(new { Role = role });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "Erro ao processar o token.", Details = ex.Message });
        }
    }

    /// <summary>
    /// Authenticates a user based on the provided login credentials and generates a JWT token for valid credentials.
    /// </summary>
    /// <param name="loginModel">An object containing the user's email and password for authentication.</param>
    /// <returns>
    /// Returns an IActionResult that indicates the outcome of the login process:
    /// - Returns Ok with a JWT token if the credentials are valid.
    /// - Returns Unauthorized if the credentials are invalid.
    /// - Returns BadRequest if the login model is null or contains missing information.
    /// </returns>
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginModel loginModel)
    {
        if (loginModel == null || string.IsNullOrEmpty(loginModel.Email) || string.IsNullOrEmpty(loginModel.Password))
            return BadRequest("Modelo de login inválido.");

        var user = await _context.Users.SingleOrDefaultAsync(u => u.Email == loginModel.Email);

        if (user == null || !_passwordHasher.VerifyPassword(loginModel.Password, user.Password)) return Unauthorized();

        var tokenHandler = new JwtSecurityTokenHandler();
        var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]);
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.Email, user.Email),
                new Claim("userId", user.Id.ToString()),
                new Claim(ClaimTypes.Role, user.Role.ToString())
            }),
            Expires = DateTime.UtcNow.AddHours(1),
            Issuer = _configuration["Jwt:Issuer"],
            Audience = _configuration["Jwt:Audience"],
            SigningCredentials =
                new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return Ok(new LoginResponse { Token = tokenHandler.WriteToken(token) });
    }

    /// <summary>
    /// Logs out the current user, terminating their session.
    /// </summary>
    /// <returns>
    /// Returns an Ok result indicating that the logout process was successful.
    /// </returns>
    [HttpPost("logout")]
    public IActionResult Logout()
    {
        return Ok("Logout realizado com sucesso.");
    }
}

public class LoginModel
{
    public string Email { get; set; }
    public string Password { get; set; }
}