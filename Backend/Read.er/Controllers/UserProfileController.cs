﻿using Amazon.S3;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models.Users;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserProfileController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITokenService _tokenService;
    private S3Service _s3Service;
    private Mock<ITokenService> mockTokenService;

    public UserProfileController(AppDbContext context, ITokenService tokenService, S3Service s3Service)
    {
        _context = context;
        _s3Service = s3Service;
        _tokenService = tokenService;
    }

    /// <summary>
    /// Updates the user profile based on the provided ID and profile data.
    /// </summary>
    /// <param name="id">The ID of the user whose profile is to be updated.</param>
    /// <param name="dto">The data transfer object containing the updated profile information.</param>
    /// <returns>Returns an IActionResult indicating the result of the update operation, which could be a success or an error message.</returns>
    [HttpPut]
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UpdateProfileDTO dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (dto.Email.Length > 100)
            return BadRequest("O email não pode ter mais de 100 caracteres.");

        if (string.IsNullOrEmpty(dto.Username))
            return BadRequest("O nome de utilizador não pode estar vazio.");

        if (dto.Username.Length > 50)
            return BadRequest("O nome de utilizador não pode ter mais de 50 caracteres.");

        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return NotFound("User not found");

        user.Username = dto.Username;
        user.Email = dto.Email;
        user.Nome = dto.Nome;
        user.Nascimento = dto.Nascimento;
        user.Bio = dto.bio;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return StatusCode(500, "An error occured while updating the profile.");
        }

        return Ok(new Dictionary<string, object> { { "message", "Profile updated successfully!" } });
    }

    /// <summary>
    /// Uploads a profile picture for the authenticated user and updates the user's profile with the URL of the uploaded image.
    /// </summary>
    /// <param name="file">The image file to be uploaded as the new profile picture.</param>
    /// <returns>Returns an IActionResult containing the URL of the uploaded profile picture if successful, or an error message indicating the type of failure.</returns>
    [HttpPost("upload-profile-picture")]
    public async Task<IActionResult> UploadProfilePicture([FromForm] IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { Message = "Nenhum arquivo foi enviado." });
            }

            var userId = _tokenService.GetUserIdByToken();
            if (userId == 0)
            {
                return Unauthorized(new { Message = "Token inválido." });
            }

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return NotFound(new { Message = "Usuário não encontrado." });
            }

            var fileName = $"{userId}/{Guid.NewGuid()}_{file.FileName}";

            using var stream = file.OpenReadStream();
            var fileUrl = await _s3Service.UploadFileAsync(stream, fileName, file.ContentType);

            user.ProfilePictureUrl = fileUrl;
            await _context.SaveChangesAsync();

            return Ok(new { Url = fileUrl });
        }
        catch (AmazonS3Exception ex)
        {
            // Erro específico do AWS S3
            Console.WriteLine($"Erro S3: {ex.Message}");
            return StatusCode(500, new { Message = "Erro ao salvar arquivo no AWS S3.", Details = ex.Message });
        }
        catch (Exception ex)
        {
            // Erro genérico
            Console.WriteLine($"Erro interno: {ex.Message}");
            return StatusCode(500, new { Message = "Erro interno no servidor.", Details = ex.Message });
        }
    }

    /// <summary>
    /// Retrieves the profile information for the authenticated user.
    /// </summary>
    /// <returns>Returns an IActionResult containing the user's profile data, which includes basic user information along with counts of posts, communities, and friends. It may return unauthorized or not found responses if the user is not authenticated or does not exist.</returns>
    [HttpGet("profile")]
    [Authorize]
    public async Task<IActionResult> GetProfile()
    {
        try
        {
            // Extrai o userId do token JWT
            var userIdClaim = User.Claims.FirstOrDefault(c => c.Type == "userId");
            if (userIdClaim == null)
            {
                return Unauthorized(new { Message = "Token inválido ou não contém o ID do utilizador." });
            }

            var userId = int.Parse(userIdClaim.Value);

            var user = await _context.Users
                .Include(u => u.Posts) // Inclui os posts do usuário, se necessário
                .Include(u => u.UserCommunities) // Inclui comunidades
                .SingleOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                return NotFound(new { Message = "Usuário não encontrado." });
            }

            // Retorna os dados do usuário (use um DTO para evitar expor informações sensíveis)
            var userProfile = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.Nome,
                user.Nascimento,
                user.ProfilePictureUrl,
                PostsCount = user.Posts.Count,
                CommunitiesCount = user.UserCommunities.Count,
                FriendsCount = user.ReceivedFriendRequests.Count + user.SentFriendRequests.Count,
                user.Bio

            };

            return Ok(userProfile);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "Erro ao processar o perfil.", Details = ex.Message });
        }
    }

    /// <summary>
    /// Retrieves the profile information of a specified user by their user ID.
    /// </summary>
    /// <param name="userId">The ID of the user whose profile is to be retrieved.</param>
    /// <returns>Returns an IActionResult containing the user's profile data including ID, username, books read count, friends count, and communities count, or a not found error if the user does not exist.</returns>
    [HttpGet("OtherUserProfile/{userId}")]
    public async Task<IActionResult> GetOtherUserProfile(int userId)
    {
        var user = await GetUserByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new { Message = "Usuário não encontrado." });
        }

        var booksReadedCount = await GetBooksReadedCountByUserIdAsync(userId);
        var friendsCount = await GetFriendsCountByUserIdAsync(userId);
        // var communitiesCount = await GetCommunitiesCountByUserIdAsync(userId);

        var userProfileDto = new OtherUserProfileDto
        {
            Id = user.Id,
            Username = user.Username,
            // Bio = user.Bio,
            // ProfilePictureUrl = user.ProfilePictureUrl,
            BooksReadedCount = booksReadedCount,
            FriendsCount = friendsCount,
            CommunitiesCount = 0,
        };

        return Ok(userProfileDto);
    }


    /// <summary>
    /// Retrieves a user entity from the database by their unique user ID.
    /// </summary>
    /// <param name="userId">The unique identifier of the user to be retrieved.</param>
    /// <returns>Returns a Task containing the user object if found; otherwise, null.</returns>
    private async Task<User> GetUserByIdAsync(int userId)
    {
        return await _context.Users
            .FirstOrDefaultAsync(u => u.Id == userId);
    }

    /// <summary>
    /// Retrieves the count of books read by a user specified by their user ID.
    /// </summary>
    /// <param name="userId">The ID of the user whose read books count is to be obtained.</param>
    /// <returns>Returns the total number of books that the user has marked as read.</returns>
    private async Task<int> GetBooksReadedCountByUserIdAsync(int userId)
    {
        return await _context.PersonalLibraries
            .CountAsync(b => b.UserId == userId && b.Status == Enumeracoes.Status.Read);
    }

    /// <summary>
    /// Asynchronously retrieves the count of friends for a user by their user ID.
    /// </summary>
    /// <param name="userId">The ID of the user whose friends count is to be retrieved.</param>
    /// <returns>Returns a task that represents the asynchronous operation. The task result contains the number of confirmed friendships for the user.</returns>
    private async Task<int> GetFriendsCountByUserIdAsync(int userId)
    {
        return await _context.UserFriendship
            .CountAsync(f => (f.ReceiverId == userId || f.RequesterId == userId) && f.IsConfirmed);


    }

}