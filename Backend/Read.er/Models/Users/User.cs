using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Read.er.Enumeracoes;
using Read.er.Models.Book;
using Read.er.Models.Communities;
using Read.er.Models.Posts;

namespace Read.er.Models.Users;

/// <summary>
/// Represents a user within the system.
/// </summary>
/// <remarks>
/// This class holds information about a system user, including their identification,
/// personal information, and various relational data such as posts and friendships.
/// </remarks>
public class User
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] [MaxLength(50, ErrorMessage = "O comprimento não pode exceder os 50 caracteres.")] 
    public string Username { get; set; } = string.Empty;

    [Required] public Role Role { get; set; }

    [Required]
    [EmailAddress]
    [MaxLength(100, ErrorMessage = "O comprimento não pode exceder os 100 caracteres.")]
    public string Email { get; set; } = string.Empty;

    [Required]
    [MaxLength(250, ErrorMessage = "O comprimento não pode exceder os 250 caracteres.")]
    public string Password { get; set; } = string.Empty;

    [Required]
    [MaxLength(150, ErrorMessage = "O comprimento não pode exceder os 150 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Required] public DateOnly Nascimento { get; set; }
    public bool IsActive { get; set; } = true;
    
    [MaxLength(250, ErrorMessage = "Limite de 250 caractéres. ")]
    public string Bio { get; set; }
    
    public string? ProfilePictureUrl { get; set; }

    [JsonIgnore]
    public ICollection<Post> Posts { get; set; } = new List<Post>();

    [JsonIgnore]
    public ICollection<UserFriendship> SentFriendRequests { get; set; } = new List<UserFriendship>();

    [JsonIgnore]
    public ICollection<UserFriendship> ReceivedFriendRequests { get; set; } = new List<UserFriendship>();

    [JsonIgnore]
    public ICollection<FollowAuthors> Following { get; set; } = new List<FollowAuthors>();

    [JsonIgnore]
    public ICollection<FollowAuthors> Followers { get; set; } = new List<FollowAuthors>();

    [JsonIgnore]
    public ICollection<UserCommunity> UserCommunities { get; set; } = new List<UserCommunity>();

    [JsonIgnore]
    public ICollection<BookReview> BookReviews { get; set; } = new List<BookReview>();




    public static implicit operator User(ValueTask<User?> v)
    {
        throw new NotImplementedException();
    }
}