using System;
namespace Read.er.DTOs
{
    /// <summary>
    /// Data Transfer Object (DTO) representing a post in the application.
    /// </summary>
    /// <remarks>
    /// The PostDto class encapsulates the properties associated with a social media
    /// type post entity within the application, providing a streamlined way to transfer
    /// post data across different layers of the application.
    /// </remarks>
    public class PostDto
    {
        public int PostId { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; }
        public string? OriginalUsername { get; set; } // Nome do autor original
        public int? OriginalPostId { get; set; } // Identificador do post original
        public string Content { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? CommunityId { get; set; }
        public int? TopicId { get; set; }
        public string Isbn { get; set; }
        public bool IsReported { get; set; }
        public int NumberOfComments { get; set; }
        public int NumberOfReactions { get; set; }
        public int NumberOfReposts { get; set; }
        public String BookTitle { get; set; }
    }


}

