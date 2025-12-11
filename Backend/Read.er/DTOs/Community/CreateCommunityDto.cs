namespace Read.er.DTOs.Community;

/// <summary>
/// Represents a data transfer object for creating a new community.
/// </summary>
public class CreateCommunityDto
{
    public string CommunityName { get; set; }
    public string CommunityDescritpion { get; set; }
}