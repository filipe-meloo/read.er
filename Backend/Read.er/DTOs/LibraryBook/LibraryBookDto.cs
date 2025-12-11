using Read.er.Enumeracoes;

namespace Read.er.DTOs.LibraryBook;

/// <summary>
/// Represents data transfer object for a library book.
/// </summary>
public class LibraryBookDto
{
    public string Isbn { get; set; }
    public string Title { get; set; }
    public string Author { get; set; }
    public string Description { get; set; }
    public DateTime? PublishDate { get; set; }
    public decimal? Price { get; set; }
    public Status Status { get; set; }
    public string Genre { get; set; }
    public int? Length { get; set; }
    public int? PagesRead { get; set; }
    public float? PercentageRead { get; set; }
    public string CoverUrl { get; set; }
    public string? VolumeId { get; set; }
}

