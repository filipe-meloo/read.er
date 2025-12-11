using System;
namespace Read.er.DTOs
{
    /// <summary>
    /// Represents a Data Transfer Object for book search results.
    /// </summary>
    /// <remarks>
    /// The SearchBookDto is used to encapsulate the details of a book as returned by external book search services such as the Google Books API.
    /// It contains various properties to provide comprehensive information about a book, including identifiers, descriptive information, and metadata.
    /// </remarks>
    public class SearchBookDto
    {
        public string ISBN { get; set; }
        public string Title { get; set; }
        public string Author { get; set; }
        public string Description { get; set; }
        public DateTime? PublishDate { get; set; }
        public string Genre { get; set; }
        public int Length { get; set; }
        public string CoverUrl { get; set; }
        public string VolumeId { get; set; }
    }
}