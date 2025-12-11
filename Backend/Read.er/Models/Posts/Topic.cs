using System.ComponentModel.DataAnnotations;
using Read.er.Models.Communities;

namespace Read.er.Models.Posts;

/// <summary>
/// Represents a topic within the application. A topic serves as a means to group posts
/// under a specific theme or subject, allowing for categorization and organization.
/// </summary>
public class Topic
{
    [Key] public int Id { get; set; }

    [Required]
    [MaxLength(100, ErrorMessage = "O comprimento não pode exceder os 100 caracteres.")]
    public string Name { get; set; } = string.Empty;

    public ICollection<Post> Posts { get; set; }
    public ICollection<CommunityTopic> CommunityTopics { get; set; }
}