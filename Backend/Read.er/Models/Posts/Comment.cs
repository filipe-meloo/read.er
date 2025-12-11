using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Models.Users;

namespace Read.er.Models.Posts;

/// <summary>
/// Represents a comment made on a post within the application.
/// </summary>
public class Comment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int PostId { get; set; }
    public Post Post { get; set; }

    [Required] public int UserId { get; set; }
    public User User { get; set; }

    [Required]
    [MaxLength(250, ErrorMessage = "O comprimento não pode exceder os 250 caracteres.")]
    public string Content { get; set; } = string.Empty;

    [Required] public DateTime CreatedAt { get; set; } = DateTime.Now;
}