using Read.er.Enumeracoes;

namespace Read.er.DTOs.LibraryBook;

/// <summary>
/// Represents the data transfer object used to add a book to the library.
/// </summary>
public class AddBookToLibraryDto
{
    public string Title { get; set; }
    public Status Status { get; set; }
    public int PagesRead { get; set; }
    public DateTime? DateRead { get; set; }
}