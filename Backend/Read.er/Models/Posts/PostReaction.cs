using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes.Post;
using Read.er.Models.Users;

namespace Read.er.Models.Posts;

/// <summary>
/// Represents a reaction made by a user on a post.
/// </summary>
public class PostReaction
{
    [Key] public int Id { get; set; }

    [Required] public int PostId { get; set; }
    public Post Post { get; set; }

    [Required] public int UserId { get; set; }
    public User User { get; set; }

    [Required] public ReactionType ReactionType { get; set; }

    [Required] public DateTime ReactionDate { get; set; } = DateTime.Now;
}