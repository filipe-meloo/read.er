using System;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Users;

namespace Read.er.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FollowAuthorsController : ControllerBase
	{
        private readonly AppDbContext _context;
        private readonly ITokenService _tokenService;

        public FollowAuthorsController(AppDbContext context, ITokenService tokenService) {
            _context = context;
            _tokenService = tokenService;
        }

        /// <summary>
        /// Allows a user to follow an author. Checks if the user is already following the author.
        /// </summary>
        /// <param name="dto">The data transfer object containing the author's ID to be followed.</param>
        /// <returns>An <see cref="IActionResult"/> indicating the result of the follow operation:
        /// either success message or a bad request if the user is already following the author.</returns>
        [HttpPost("Create")]
        [Authorize(Roles = "Leitor")]
        public async Task<IActionResult> FollowAuthor([FromBody] FollowAuthorDto dto) {
            var userId = _tokenService.GetUserIdByToken();

            var follows = _context.FollowAuthors.FirstOrDefault(fa => fa.AuthorId == dto.AuthorId && fa.UserId == userId);

            if (follows != null) {
                return BadRequest("Este user ja segue este autor.");
            }
            var newFollow = new FollowAuthors
            {
                UserId = userId,
                AuthorId = dto.AuthorId
            };

            _context.FollowAuthors.Add(newFollow);
            _context.SaveChangesAsync();
            return Ok("Comecou a seguir");
        }


        /// <summary>
        /// Retrieves the list of followers for an author.
        /// </summary>
        /// <returns>An <see cref="IActionResult"/> containing the list of followers:
        /// a collection of followers if they exist or a not found result if there are no followers.</returns>
        [HttpGet("Followers")]
        [Authorize(Roles = "Autor")]
        public async Task<IActionResult> GetFollowers() {

            var userId = _tokenService.GetUserIdByToken();
            var followers = _context.FollowAuthors
                .Where(fa => fa.AuthorId == userId)
                .ToList();
            if (followers == null) {
                return NotFound("Não tem seguidores");
            }

            return Ok(followers);

        }

        /// <summary>
        /// Retrieves the total number of followers for the currently authenticated author.
        /// </summary>
        /// <returns>The count of followers associated with the author's ID.</returns>
        [HttpGet("NumberOfFollowers")]
        [Authorize(Roles = "Autor")]
        public async Task<int> GetNumberOfFo() {

            var userId = _tokenService.GetUserIdByToken();

            var followers = _context.FollowAuthors
                .Count(fa => fa.AuthorId == userId);
            return followers; 
        }
    }
}

