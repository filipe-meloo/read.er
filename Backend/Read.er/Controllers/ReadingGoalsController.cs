using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Services;

namespace Read.er.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReadingGoalsController : ControllerBase
	{
        private readonly AppDbContext _context;
        private readonly ITokenService _tokenService;
		private readonly LibraryService _libraryService;


		public ReadingGoalsController(AppDbContext context, ITokenService tokenService, LibraryService libraryService) {
			_context = context;
			_tokenService = tokenService;
			_libraryService = libraryService;

        }

		/// <summary>
		/// Creates a new reading goal for the current year if one does not already exist for the user.
		/// </summary>
		/// <param name="createGoalDto">An object containing the details of the new reading goal, including the target goal and any books already read.</param>
		/// <returns>An IActionResult indicating the result of the goal creation process. Returns a BadRequest if a goal for the year already exists for the user, or an Ok result if the goal is successfully created.</returns>
		[HttpPost("Create")]
		public async Task<IActionResult> CreateReadingGoal([FromBody] CreateGoalDto createGoalDto) {

			int userId = _tokenService.GetUserIdByToken();
            var books_readed = _libraryService.GetNumberOfBooksRead(userId);
			var existingGoal = _context.ReadingGoals
                .FirstOrDefault(rg => rg.UserId == userId && rg.Year == DateTime.UtcNow.Year);
			if (existingGoal != null) {
				return BadRequest("Utilizador ja criou um Goal para este ano.");
			}

			var newreadingGoal = new ReadingGoal
			{

				UserId = userId,
				Goal = createGoalDto.Goal,
				BooksRead = await books_readed,
				Year = DateTime.UtcNow.Year,
				DateCreated = DateTime.UtcNow,
			};
			_context.ReadingGoals.Add(newreadingGoal);
			await _context.SaveChangesAsync();

			return Ok("Reading Goals criada com sucesso.");
        }

		/// <summary>
		/// Updates an existing reading goal for the current user.
		/// </summary>
		/// <param name="id">The identifier of the reading goal to be updated.</param>
		/// <param name="dto">An object containing the new target goal for the reading plan.</param>
		/// <returns>An action result indicating the success or failure of the update operation.</returns>
		[HttpPut("Update")]
		public async Task<IActionResult> UpdateGoal(int id, [FromBody] UpdateGoalDto dto) {

			var userId = _tokenService.GetUserIdByToken();
			var goalToUpdate = _context.ReadingGoals.FirstOrDefault(rg => rg.Id == id && rg.UserId == userId);

			if (goalToUpdate == null) {
				return NotFound("Não existe essa reading goal para este user");
			}

			goalToUpdate.Goal = dto.newGoal;

            await _context.SaveChangesAsync();

			return Ok("Goal alterado com sucesso!");
		}

		/// <summary>
		/// Retrieves and displays the reading goal for the current year for the authenticated user.
		/// </summary>
		/// <returns>An IActionResult containing the user's reading goal for the current year as a ViewGoalsDto object if it exists; otherwise, a NotFound result with a message indicating that no reading goal is set for the current year.</returns>
		[HttpGet("View Reading Goal")]
		public async Task<IActionResult> ViewGoal() {

			var userId = _tokenService.GetUserIdByToken();
			var readingGoal = _context.ReadingGoals.FirstOrDefault(rg => rg.Year == DateTime.UtcNow.Year && rg.UserId == userId);

			if (readingGoal == null) {
				return NotFound("Voce nao tem um reading goal este ano. Crie um para alcançar seus objetivos!");
			}

			var readingGoalDto = new ViewGoalsDto
			{
				Year = readingGoal.Year,
				Goal = readingGoal.Goal,
				BooksRead = readingGoal.BooksRead,
				RemainingBooks = readingGoal.Goal - readingGoal.BooksRead >= 0 ? readingGoal.Goal - readingGoal.BooksRead : 0
			};
			return Ok(readingGoalDto);
		}
	}
}

