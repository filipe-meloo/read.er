using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs.Community;

/// <summary>
/// Represents data required for a user to join a community.
/// </summary>
public class JoinCommunityRequestDto
{
    public int UserId { get; set; }

    [Required] public int CommunityId { get; set; }

    [Required] public DateTime EntryDate { get; set; } = DateTime.Now;

    [Required] public CommunityRole Role { get; set; }
}