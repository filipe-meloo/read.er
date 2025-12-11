using Read.er.Models.Communities;
using Read.er.Models.Posts;
using Read.er.Models.Users;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

/// <summary>
/// Represents a Community entity with information about its administrator, members, and posts.
/// </summary>
public class Community
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int AdminId { get; set; }
    public User Admin { get; set; }

    [Required]
    [MaxLength(50, ErrorMessage = "O comprimento não pode exceder os 50 caracteres.")]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(300, ErrorMessage = "O comprimento não pode exceder os 300 caracteres.")]
    public string Description { get; set; } = string.Empty;

    [Required] public bool IsBlocked { get; set; } = false;
    
    public string? ProfilePictureUrl { get; set; } // URL da foto de perfil da comunidade

    [JsonIgnore] public ICollection<UserCommunity> Members { get; set; }
    [JsonIgnore] public ICollection<Post> Posts { get; set; }
    [JsonIgnore] public ICollection<CommunityTopic> CommunityTopics { get; set; }
}