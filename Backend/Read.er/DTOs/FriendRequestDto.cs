namespace Read.er.DTOs;

/// <summary>
/// Represents a data transfer object for a friend request.
/// </summary>
public class FriendRequestDto
{
    public int RequesterId { get; set; }
    public string RequesterName { get; set; }
    public string RequesterUsername { get; set; }
    public bool IsConfirmed { get; set; }
}