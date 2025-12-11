using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Read.er.Models.Book;

/// <summary>
/// Represents a reading goal set by a user for a specific year.
/// </summary>
public class ReadingGoal
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int UserId { get; set; }

    [Required] public int Year { get; set; }

    [Required] public int Goal { get; set; }

    [Required] public int BooksRead { get; set; }

    [Required] public DateTime DateCreated { get; set; } = DateTime.UtcNow;
}