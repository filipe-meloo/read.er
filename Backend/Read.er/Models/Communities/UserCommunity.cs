using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Read.er.Enumeracoes;
using Read.er.Models.Users;

namespace Read.er.Models.Communities;

/// <summary>
/// Represents an association between a user and a community within the system.
/// This class manages the membership details of a user in a specific community.
/// </summary>
public class UserCommunity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int UserId { get; set; }
    [JsonIgnore]
    public User User { get; set; }

    [Required] public int CommunityId { get; set; }

    [JsonIgnore]
    public Community Community { get; set; }

    [Required] public int MemberNumber { get; set; }

    public bool IsPending { get; set; }

    [Required] public DateTime EntryDate { get; set; } = DateTime.Now;

    [Required] public CommunityRole Role { get; set; }
}