using Read.er.Enumeracoes;

namespace Read.er.DTOs.LibraryBook;

/// <summary>
/// Data transfer object for updating the status of a book in the user's personal library.
/// </summary>
public class UpdateBookStatusDto
{
    public string Isbn { get; set; }

    public int? PagesRead { get; set; }

    public Status Status { get; set; }
}