namespace Read.er.Models.Users;

/// <summary>
/// Represents a relationship where a user follows an author within the application.
/// This class serves as a link between users who are readers and users who are authors,
/// allowing tracking of authors followed by readers.
/// </summary>
public class FollowAuthors
{
    public int UserId { get; set; }
    public User Leitor { get; set; }

    public int AuthorId { get; set; }
    public User Author { get; set; }
}