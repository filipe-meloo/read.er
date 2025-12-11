using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.Interfaces;
using Read.er.Models.Book;

namespace Read.er.Services;

public class BookService : IBookService
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;

    public BookService(AppDbContext context, IGoogleBooksService googleBooksService)
    {
        _context = context;
        _googleBooksService = googleBooksService;
    }

    public async Task<CacheBook> GetBookByIsbnAsync(string isbn)
    {
        var book = await _context.CachedBooks.FirstOrDefaultAsync(b => b.Isbn == isbn);
        if (book != null) return book;

        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);

        if (bookDetails == null)
        {
            Console.WriteLine($"Book details not found for ISBN: {isbn}");
            return null;
        }

        var newCacheBook = new CacheBook
        {
            Isbn = isbn,
            Title = bookDetails.Title ?? "Título Padrão",
            Author = bookDetails.Author ?? "Autor Padrão",
            Description = bookDetails.Description ?? "Descrição Padrão",
            VolumeId = bookDetails.VolumeId ?? "Volume ID desconhecido", // Armazena como string
            CoverUrl = !string.IsNullOrEmpty(bookDetails.CoverUrl) ? bookDetails.CoverUrl : "URL padrão",
            Length = bookDetails.Length ?? 0,
            UserId = 0 // Defina um valor padrão ou lógica adequada para o UserId
        };

        await _context.CachedBooks.AddAsync(newCacheBook);
        await _context.SaveChangesAsync();

        return newCacheBook;
    }

    public async Task ReprocessCachedBooksAsync()
    {
        // Obtém todos os livros armazenados no cache
        var cachedBooks = await _context.CachedBooks.ToListAsync();

        foreach (var book in cachedBooks)
        {
            // Busca os detalhes do livro usando o serviço do Google Books
            var details = await _googleBooksService.FetchBookDetailsByIsbn(book.Isbn);

            if (details != null)
            {
                Console.WriteLine($"Processing book with ISBN: {book.Isbn}");

                // Atualiza o campo CoverUrl se o valor obtido for válido
                if (!string.IsNullOrEmpty(details.CoverUrl))
                {
                    book.CoverUrl = details.CoverUrl;
                    Console.WriteLine($"Updated CoverUrl for ISBN {book.Isbn}: {details.CoverUrl}");
                }

                // Atualiza o campo VolumeId como string diretamente
                if (!string.IsNullOrEmpty(details.VolumeId))
                {
                    book.VolumeId = details.VolumeId;
                    Console.WriteLine($"Updated VolumeId for ISBN {book.Isbn}: {details.VolumeId}");
                }
                else
                {
                    Console.WriteLine($"No VolumeId found for ISBN {book.Isbn}");
                }
            }
            else
            {
                Console.WriteLine($"No details found for ISBN: {book.Isbn}");
            }
        }

        // Salva as alterações no banco de dados
        await _context.SaveChangesAsync();
    }
    
}
