using System.ComponentModel.DataAnnotations;

namespace Read.er.Models.Users;

/// <summary>
/// Represents a friendship relationship between two users in the system.
/// </summary>
public class UserFriendship
{
    [Key] public int RequesterId { get; set; }
    public User Requester { get; set; }

    [Key] public int ReceiverId { get; set; }
    public User Receiver { get; set; }

    public bool IsConfirmed { get; set; }
}