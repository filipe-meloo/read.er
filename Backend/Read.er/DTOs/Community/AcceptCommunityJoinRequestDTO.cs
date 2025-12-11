namespace Read.er.DTOs.Community;

/// <summary>
/// Represents a data transfer object for accepting a join request to a community.
/// </summary>
public class AcceptCommunityJoinRequestDto
{
    public int AdminId { get; set; }
    public int UserCommunityId { get; set; }
    public int CommunityId { get; set; }
}