using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes.Books;
using Read.er.Models.Users;

namespace Read.er.Models.Book;

/// <summary>
/// Represents a book written by a writer with specific attributes
/// such as publication date, pricing, and promotion status.
/// </summary>
public class WriterBook : BookBase
{
    public int Id { get; set; }
    
    [Required] public int WriterId { get; set; }
    public User Writer { get; set; }
    
    [Required]
    public DateTime PublishDate { get; set; }
    
    [Required]
    public decimal Price { get; set; }
    
    public WriterBookStatus Status { get; set; } = WriterBookStatus.Pending;

    [MaxLength(300, ErrorMessage = "O comprimento não pode exceder os 300 caracteres.")]
    public string? RejectionReason { get; internal set; } = string.Empty;
    
    public bool IsPromoted { get; set; } = false;
}