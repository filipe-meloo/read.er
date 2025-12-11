namespace Read.er.DTOs;

/// <summary>
/// Represents the data transfer object for marking a post as inappropriate.
/// </summary>
public class MarkPostDto
{
    public string Message { get; set; }
    public int PostId { get; set; }
}

/// <summary>
/// Represents the data transfer object for deleting a post.
/// </summary>
public class DeletePostDto
{
    public string Message { get; set; }
    public int PostId { get; set; }
}

/// <summary>
/// Represents the data transfer object for toggling the active status of a user.
/// </summary>
public class ToggleDto
{
    public string Message { get; set; }
    public int UserId { get; set; }
    public bool IsActive { get; set; }
}