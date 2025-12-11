using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using Read.er.DTOs;
using Read.er.DTOs.LibraryBook;
using Read.er.Models.Book;

namespace Read.er.Interfaces
{
    public interface IGoogleBooksService
    {
        
        /// <summary>
        /// Searches a book by its ISBN and returns a JSON object from Google Books API.
        /// </summary>
        /// <param name="isbn">The ISBN to search for.</param>
        /// <returns>A JSON object containing the book details if found, otherwise null.</returns>
        Task<JObject> GetBookByIsbnAsync(string isbn);
        
        /// <summary>
        /// Retrieves the ISBN-13 of a book by its title using the Google Books API.
        /// </summary>
        /// <param name="title">The title of the book.</param>
        /// <returns>The ISBN if found, otherwise an error message.</returns>
        Task<string> GetIsbnByTitle(string title);
        
        /// <summary>
        /// Retrieves book details by its ISBN using the Google Books API.
        /// </summary>
        /// <param name="isbn">The ISBN of the book.</param>
        /// <returns>The book details if found, otherwise <c>null</c>.</returns>
        Task<LibraryBookDto> FetchBookDetailsByIsbn(string isbn);
        
        /// <summary>
        /// Searches for books by title using the Google Books API.
        /// </summary>
        /// <param name="title">The title of the book to search for.</param>
        /// <returns>
        /// A list of <see cref="SearchBookDto"/> objects containing details of the books found,
        /// or null if an error occurs during the search.
        /// </returns>
        /// <remarks>
        /// This method constructs a request to the Google Books API with the specified title,
        /// processes the response to extract book details, and maps them to a list of DTOs.
        /// </remarks>
        Task<List<SearchBookDto>> SearchGoogleBooksByTitleAsync(string title);
        
        /// <summary>
        /// Retrieves the title of a book using its ISBN via the Google Books API.
        /// </summary>
        /// <param name="isbn">The ISBN of the book to search for.</param>
        /// <returns>
        /// The title of the book if found; otherwise, returns an error message such as 
        /// "Título não disponível", "Erro de rede", or "Erro desconhecido".
        /// </returns>
        Task<string> GetTitleByIsbn(string isbn);
    }
}