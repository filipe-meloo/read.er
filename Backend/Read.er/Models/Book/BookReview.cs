using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Models.Users;

namespace Read.er.Models.Book;

/// <summary>
/// Represents a review of a book provided by a user.
/// </summary>
public class BookReview : BookBase
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; } // Renomeado de IdUser para UserId
    public User User { get; set; }

    [Required]
    [Range(1, 5, ErrorMessage = "Valor tem de estar entre 1 e 5.")]
    public int Rating { get; set; }

    [Required]
    [MaxLength(300, ErrorMessage = "O comprimento não pode exceder os 300 caracteres.")]
    public string? Comment { get; set; }

    [Required]
    public DateTime Date { get; set; } = DateTime.UtcNow;
}
