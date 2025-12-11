using Read.er.Models.Book;
using Read.er.Models.Users;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

/// <summary>
/// Represents a cached book record within the application.
/// </summary>
/// <remarks>
/// This class is primarily used to cache book information retrieved from external sources
/// to improve performance and reduce redundant data fetching.
/// </remarks>
public class CacheBook : BookBase
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    public string EmbeddingString { get; set; }

    [Required]
    public int UserId { get; set; }
    public User User { get; set; }

    public int Length { get; set; }
    public string VolumeId { get; set; } // Alterado para int? para permitir nulos
    public string CoverUrl { get; set; }

    [NotMapped]
    public float[] Embedding
    {
        get
        {
            if (string.IsNullOrWhiteSpace(EmbeddingString))
                return Array.Empty<float>();

            return EmbeddingString.Split(',')
                .Select(s => float.TryParse(s, out var f) ? f : 0f)
                .ToArray();
        }
        set => EmbeddingString = value == null ? null : string.Join(",", value);
    }
}
