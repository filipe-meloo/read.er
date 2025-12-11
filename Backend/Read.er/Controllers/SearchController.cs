using Microsoft.AspNetCore.Mvc;
using Read.er.Interfaces;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SearchController : ControllerBase
{
    private readonly IGoogleBooksService _bookService;

    public SearchController(IGoogleBooksService bookService)
    {
        _bookService = bookService;
    }

    /// <summary>
    /// Searches for books by title using the Google Books API.
    /// </summary>
    /// <param name="title">The title of the book to search for.</param>
    /// <returns>
    /// An <see cref="IActionResult"/> containing a list of <see cref="SearchBookDto"/> objects if the search is successful.
    /// Returns a "NotFound" response if no books are found with the specified title.
    /// </returns>
    [HttpGet("searchByTitle")]
    public async Task<IActionResult> SearchBooksByTitle([FromQuery] string title)
    {
        var results = await _bookService.SearchGoogleBooksByTitleAsync(title);
        if (results == null || !results.Any())
        {
            return NotFound("Nenhum livro encontrado com o título especificado.");
        }
        return Ok(results);
    }

}