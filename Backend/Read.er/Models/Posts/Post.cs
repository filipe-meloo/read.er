using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;
using Read.er.Models.Users;

namespace Read.er.Models.Posts;

/// <summary>
/// Represents a social media post within the application.
/// </summary>
public class Post
{
    [Key] public int Id { get; set; }

    public int? OriginalPostId { get; set; }
    public Post OriginalPost { get; set; }
    
    [Required] public int IdUser { get; set; }
    public User User { get; set; }

    [Required]
    [MaxLength(350, ErrorMessage = "O comprimento não pode exceder os 350 caracteres.")]
    public string Conteudo { get; set; } = string.Empty;

    [Required] public DateTime DataCriacao { get; set; } = DateTime.Now;

    [Required] public TipoPublicacao TipoPublicacao { get; set; }

    [Required]
    [MaxLength(13)]
    [RegularExpression("(.{10}|.{13})", ErrorMessage = "Comprimento deve ser 10 ou 13.")]
    public string Isbn { get; set; } = string.Empty;

    public int? CommunityId { get; set; }

    public int? TopicId { get; set; }

    [Required]
    [MaxLength(40, ErrorMessage = "O comprimento não pode exceder os 40 caracteres.")]
    public string BookTitle { get; set; }

    [Required] public bool IsInappropriate { get; set; } = false;
    [Required] public bool IsReported { get; set; } = false;
    [Required] public bool Solved { get; set; } = false;

    public StatusPost Status { get; set; } = StatusPost.Active;
    
    public ICollection<Comment> Comments { get; set; }  
}