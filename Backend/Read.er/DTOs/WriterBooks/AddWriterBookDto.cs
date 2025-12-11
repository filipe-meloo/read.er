namespace Read.er.DTOs.WriterBooks;

/// <summary>
/// Represents a Data Transfer Object for adding a book associated with a writer.
/// </summary>
public class AddWriterBookDto
{
    public string ISBN { get; set; }
    public decimal? Price { get; set; }
}