using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes.Books;
using Read.er.Models;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class BookApprovalController : ControllerBase
{
    private readonly AppDbContext _context;

    public BookApprovalController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Approves a book by its identifier if it is currently not approved.
    /// </summary>
    /// <param name="bookId">The identifier of the book to be approved.</param>
    /// <returns>
    /// Returns a task that on completion provides an IActionResult indicating the result of the operation:
    /// - Ok result if the book is approved successfully.
    /// - NotFound result if the book with the specified identifier is not found.
    /// - BadRequest result if the book is already approved.
    /// - StatusCode 500 if a database update error occurs.
    /// </returns>
    [HttpPost("approve/{bookId}")]
    public async Task<IActionResult> ApproveBook([FromRoute] int bookId)
    {
        var book = await _context.WriterBooks.FindAsync(bookId);
        if (book == null) return NotFound(new { message = "Obra não encontrada." });

        if (book.Status == WriterBookStatus.Approved) return BadRequest(new { message = "A obra já está aprovada." });

        book.Status = WriterBookStatus.Approved;

        try
        {
            await _context.SaveChangesAsync();
            return Ok(new { message = "Obra aprovada com sucesso!" });
        }
        catch (DbUpdateException ex)
        {
            return StatusCode(500, new { message = "Ocorreu um erro ao aprovar a obra.", details = ex.Message });
        }
    }

    /// <summary>
    /// Rejects a book by updating its status to rejected and setting a rejection reason.
    /// </summary>
    /// <param name="bookId">The identifier of the book to be rejected.</param>
    /// <param name="dto">The data transfer object containing the reason for rejection.</param>
    /// <returns>
    /// Returns a task that on completion provides an IActionResult indicating the result of the operation:
    /// - Ok result along with a message and the rejection reason if the book is rejected successfully.
    /// - NotFound result if the book with the specified identifier is not found.
    /// - BadRequest result if the book is already rejected.
    /// - StatusCode 500 if a database update error occurs.
    /// </returns>
    [HttpPost("reject/{bookId}")]
    public async Task<IActionResult> RejectBook(int bookId, [FromBody] RejectBookDto dto)
    {
        var book = await _context.WriterBooks.FindAsync(bookId);
        if (book == null) return NotFound(new { message = "Obra não encontrada." });

        if (book.Status == WriterBookStatus.Rejected)
            return BadRequest(new { message = "A obra já foi rejeitada anteriormente." });

        book.Status = WriterBookStatus.Rejected;
        book.RejectionReason = dto.Reason;

        try
        {
            await _context.SaveChangesAsync();
            return Ok(new { message = "Obra rejeitada com sucesso!", rejectionReason = dto.Reason });
        }
        catch (DbUpdateException ex)
        {
            return StatusCode(500, new { message = "Ocorreu um erro ao rejeitar a obra.", details = ex.Message });
        }
    }
}