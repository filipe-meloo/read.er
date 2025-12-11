using Read.er.Models.Book;

namespace Read.er.Interfaces;

public interface IBookService
{
    /// <summary>
    /// Find a book in the cache by its ISBN and returns it.
    /// If the book is not found, it fetches the book details from Google Books API,
    /// creates a new CacheBook and adds it to the cache.
    /// </summary>
    /// <param name="isbn">The ISBN of the book to find.</param>
    /// <returns>The CacheBook with the given ISBN.</returns>
    Task<CacheBook> GetBookByIsbnAsync(string isbn);
    Task ReprocessCachedBooksAsync(); 
}