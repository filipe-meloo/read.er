using System;
namespace Read.er.DTOs;

/// <summary>
/// Data Transfer Object (DTO) for representing a book review.
/// </summary>
/// <remarks>
/// This DTO is used to encapsulate the data required for a book review, including the book's ISBN,
/// a rating, and an optional comment. It is primarily used to transfer data between client and server
/// when handling operations related to book reviews.
/// </remarks>
public class BookReviewDto
{
    public string Isbn { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; }
}