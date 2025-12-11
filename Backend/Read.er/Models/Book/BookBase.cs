using System.ComponentModel.DataAnnotations;

namespace Read.er.Models.Book;

/// <summary>
/// Represents the base characteristics of a book, including metadata such as ISBN, title, author, and genre.
/// </summary>
public class BookBase
{
    [Required]
    [MaxLength(13)]
    [RegularExpression("(.{10}|.{13})", ErrorMessage = "Comprimento deve ser 10 ou 13.")]
    public string Isbn { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(150, ErrorMessage = "O comprimento não pode exceder os 150 caracteres.")]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100, ErrorMessage = "O comprimento não pode exceder os 100 caracteres.")]
    public string Author { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(3000, ErrorMessage = "O comprimento não pode exceder os 3000 caracteres.")]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100, ErrorMessage = "O comprimento não pode exceder os 100 caracteres.")]
    public string Genres { get; set; } = string.Empty;
    
    [Required] public DateTime PublishDate { get; set; }
}