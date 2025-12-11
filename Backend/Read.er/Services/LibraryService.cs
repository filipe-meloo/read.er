using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs.LibraryBook;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Services;

public class LibraryService : ILibraryService
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly EmbeddingService _embeddingService;

    public LibraryService(AppDbContext context, IGoogleBooksService googleBooksService, EmbeddingService embeddingService)
    {
        _context = context;
        _googleBooksService = googleBooksService;
        _embeddingService = embeddingService;
    }

    public async Task AddBookToCachedBooksFromLibrary(int userId, string isbn)
    {
        // Log para verificar se a função está a ser chamada
        Console.WriteLine($"Iniciando AddBookToCachedBooksFromLibrary para ISBN: {isbn} e UserId: {userId}");

        // Verifica se o livro já existe na cache
        var existingBook = await _context.CachedBooks.FirstOrDefaultAsync(cb => cb.Isbn == isbn);
        if (existingBook != null)
        {
            Console.WriteLine($"O livro com ISBN: {isbn} já existe na cache. Saindo da função.");
            return;
        }

        // Busca detalhes do livro
        var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(isbn);
        if (bookDetails == null)
        {
            Console.WriteLine($"Detalhes do livro não encontrados para ISBN: {isbn}. Saindo da função.");
            return;
        }

        // Preparar texto para gerar o embedding
        string textToEmbed = $"{bookDetails.Title ?? ""} {bookDetails.Author ?? ""} {bookDetails.Description ?? ""} {bookDetails.Genre ?? ""}";
        float[] embedding;

        try
        {
            Console.WriteLine("Gerando embedding...");
            embedding = _embeddingService.GenerateEmbedding(textToEmbed);
            Console.WriteLine("Embedding gerado com sucesso.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Erro ao gerar o embedding: {ex.Message}");
            embedding = null; // Define como null em caso de falha
        }

        // Criar o objeto CacheBook
        var cachedBook = new CacheBook
        {
            Isbn = bookDetails.Isbn ?? "ISBN Desconhecido",
            Title = bookDetails.Title ?? "Título Padrão",
            Author = bookDetails.Author ?? "Autor Padrão",
            Description = bookDetails.Description ?? "Descrição Padrão",
            PublishDate = bookDetails.PublishDate ?? DateTime.UtcNow,
            EmbeddingString = embedding != null && embedding.Any()
                ? string.Join(",", embedding) // Converte para string
                : string.Empty, // Armazena string vazia em caso de falha
            UserId = userId,
            Genres = bookDetails.Genre ?? "Gênero desconhecido",
            Length = bookDetails.Length ?? 0,
            CoverUrl = bookDetails.CoverUrl ?? "URL padrão",
            VolumeId = string.IsNullOrEmpty(bookDetails.VolumeId) ? null : bookDetails.VolumeId
        };

        // Log antes de adicionar o livro à cache
        Console.WriteLine($"Adicionando o livro com ISBN: {isbn} à cache.");
        _context.CachedBooks.Add(cachedBook);
        await _context.SaveChangesAsync();
        Console.WriteLine($"Livro com ISBN: {isbn} adicionado à cache com sucesso.");
    }




    public async Task<int> GetNumberOfBooksRead(int userId)
    {
        // Lógica para contar os livros lidos pelo utilizador
        var booksRead = await _context.PersonalLibraries
            .CountAsync(book => book.UserId == userId && book.Status == Status.Read);
        return booksRead;
    }
}
