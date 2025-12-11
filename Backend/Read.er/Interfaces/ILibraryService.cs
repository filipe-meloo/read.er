namespace Read.er.Interfaces
{
    public interface ILibraryService
    {
        /// <summary>
        /// Adds a book to the cached books for a specific user using the provided ISBN.
        /// Retrieves book details from a third-party service and generates an embedding before caching the book information.
        /// </summary>
        /// <param name="userId">The ID of the user for whom the book is being cached.</param>
        /// <param name="isbn">The ISBN of the book to be added to the cache.</param>
        /// <returns>A task that represents the asynchronous operation of adding the book to the cache.</returns>
        Task AddBookToCachedBooksFromLibrary(int userId, string isbn);
        
        /// <summary>
        /// Asynchronously retrieves the number of books read by a specific user.
        /// </summary>
        /// <param name="userId">The identifier of the user whose read books should be counted.</param>
        /// <returns>A task representing the asynchronous operation, with a result of the total number of books read by the user.</returns>
        Task<int> GetNumberOfBooksRead(int userId);
    }

}

