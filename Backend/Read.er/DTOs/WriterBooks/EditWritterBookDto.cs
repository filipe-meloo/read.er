namespace Read.er.DTOs.WriterBooks;

/// <summary>
/// Represents a Data Transfer Object (DTO) for editing the details of a writer's book.
/// </summary>
public class EditWriterBookDto
{
    public string Title { get; set; }
    public string Author { get; set; }
    public string Description { get; set; }
    public DateTime? PublishDate { get; set; }
    public decimal? Price { get; set; }
}