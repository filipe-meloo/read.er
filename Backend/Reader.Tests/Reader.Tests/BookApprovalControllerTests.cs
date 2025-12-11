using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Controllers;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Enumeracoes.Books;
using Read.er.Models;
using Read.er.Models.Book;

public class BookApprovalControllerTests
{
    private DbContextOptions<AppDbContext> CreateNewContextOptions()
    {
        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
    }

    private async Task AddBookAsync(AppDbContext context, int bookId, WriterBookStatus status = WriterBookStatus.Pending)
    {
        var book = new WriterBook
        {
            Id = bookId,
            Title = "Livro Teste",
            Author = "Jose Ricardo",
            Isbn = "1234567890",
            Description = "Uma bela obra sobre nada e tudo",
            Status = status
        };
        await context.WriterBooks.AddAsync(book);
        await context.SaveChangesAsync();
    }

    [Fact]
    public async Task ApproveBook_WithValidId_ReturnsOkResult()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddBookAsync(context, 1);
            var controller = new BookApprovalController(context);

            var result = await controller.ApproveBook(1);

            Assert.IsType<OkObjectResult>(result);
            var book = await context.WriterBooks.FindAsync(1);
            Assert.Equal(WriterBookStatus.Approved, book.Status);
        }
    }

    [Fact]
    public async Task ApproveBook_WithInvalidId_ReturnsNotFound()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var controller = new BookApprovalController(context);

            var result = await controller.ApproveBook(999);

            Assert.IsType<NotFoundObjectResult>(result);
        }
    }

    [Fact]
    public async Task ApproveBook_AlreadyApproved_ReturnsBadRequest()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddBookAsync(context, 1, WriterBookStatus.Approved);
            var controller = new BookApprovalController(context);

            var result = await controller.ApproveBook(1);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }

    [Fact]
    public async Task RejectBook_WithValidIdAndReason_ReturnsOkResult()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddBookAsync(context, 1);
            var controller = new BookApprovalController(context);
            var rejectDto = new RejectBookDto { Reason = "Content inappropriate" };

            var result = await controller.RejectBook(1, rejectDto);

            Assert.IsType<OkObjectResult>(result);
            var book = await context.WriterBooks.FindAsync(1);
            Assert.Equal(WriterBookStatus.Rejected, book.Status);
            Assert.Equal("Content inappropriate", book.RejectionReason);
        }
    }

    [Fact]
    public async Task RejectBook_WithInvalidId_ReturnsNotFound()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            var controller = new BookApprovalController(context);
            var rejectDto = new RejectBookDto { Reason = "Content inappropriate" };

            var result = await controller.RejectBook(999, rejectDto);

            Assert.IsType<NotFoundObjectResult>(result);
        }
    }

    [Fact]
    public async Task RejectBook_AlreadyRejected_ReturnsBadRequest()
    {
        using (var context = new AppDbContext(CreateNewContextOptions()))
        {
            await AddBookAsync(context, 1, WriterBookStatus.Rejected);
            var controller = new BookApprovalController(context);
            var rejectDto = new RejectBookDto { Reason = "New rejection reason" };

            var result = await controller.RejectBook(1, rejectDto);

            Assert.IsType<BadRequestObjectResult>(result);
        }
    }
}