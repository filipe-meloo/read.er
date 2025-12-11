﻿using Read.er.Data;
using Read.er.DTOs.LibraryBook;
using Read.er.Enumeracoes;
using Microsoft.EntityFrameworkCore;
using Read.er.Services;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

public class RecommendationService
{
    private readonly AppDbContext _context;
    private readonly EmbeddingService _embeddingService;

    public RecommendationService(AppDbContext context, EmbeddingService embeddingService)
    {
        _context = context;
        _embeddingService = embeddingService;
    }

    /// <summary>
    /// Retrieves a list of recommended books for a given user based on the cosine similarity of book embeddings.
    /// </summary>
    /// <param name="userId">The unique identifier of the user for whom book recommendations are requested.</param>
    /// <returns>A task that represents the asynchronous operation. The task result contains a list of <see cref="LibraryBookDto"/> representing the recommended books for the user, ordered by similarity in descending order.</returns>
    public async Task<List<LibraryBookDto>> GetRecommendationsForUser(int userId)
    {
        var userBooksISBNs = await _context.PersonalLibraries
            .Where(pl => pl.UserId == userId)
            .Select(pl => pl.Isbn.ToLower())
            .ToListAsync();

        var userBookEmbeddings = await _context.CachedBooks
            .Where(b => userBooksISBNs.Contains(b.Isbn.ToLower()))
            .Select(b => b.Embedding)
            .ToListAsync();

        var cachedBooks = await _context.CachedBooks
            .Where(cb => !userBooksISBNs.Any(userISBN => userISBN == cb.Isbn.ToLower()))
            .ToListAsync();

        var recommendations = new List<(LibraryBookDto book, float similarity)>();

        foreach (var cachedBook in cachedBooks)
        {
            var similarity = userBookEmbeddings
                .Select(e => _embeddingService.CalculateCosineSimilarity(e, cachedBook.Embedding))
                .DefaultIfEmpty(0f) // Similaridade é 0 se não houver embeddings
                .Max();

            var libraryBookDto = new LibraryBookDto
            {
                Isbn = cachedBook.Isbn,
                Title = cachedBook.Title ?? "Título desconhecido", // Tratar valores nulos
                Author = cachedBook.Author ?? "Autor desconhecido",
                Description = cachedBook.Description ?? "Descrição não disponível",
                PublishDate = cachedBook.PublishDate, // Substituir nulo por um valor padrão
                Price = null, // Supondo que o preço não está na base de dados
                Status = Status.Tbr,
                Genre = cachedBook.Genres ?? "Gênero desconhecido",
                CoverUrl = cachedBook.CoverUrl ?? "URL padrão",
                Length = cachedBook.Length,
                VolumeId = cachedBook.VolumeId ?? "Volume ID desconhecido" // Tratar VolumeId como string
            };

            recommendations.Add((libraryBookDto, similarity));
        }

        return recommendations
            .OrderByDescending(r => r.similarity)
            .Select(r => r.book)
            .ToList();
    }
}