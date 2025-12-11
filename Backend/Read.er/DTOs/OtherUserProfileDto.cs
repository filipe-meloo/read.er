using System;
namespace Read.er.DTOs
{
    /// <summary>
    /// Represents the profile data of another user within the application.
    /// </summary>
    public class OtherUserProfileDto
    {
        public int Id { get; set; }
        public string Username { get; set; }
       // public string Bio { get; set; }
       // public string ProfilePictureUrl { get; set; }
        public int BooksReadedCount { get; set; }
        public int FriendsCount { get; set; }
        public int CommunitiesCount { get; set; }
    }

}

