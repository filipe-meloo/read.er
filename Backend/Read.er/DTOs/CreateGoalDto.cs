using System;
using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs;

/// <summary>
/// Data transfer object for creating a new reading goal.
/// </summary>
/// <remarks>
/// Used to specify the target number of books to read and track books already read for a specific user.
/// </remarks>
public class CreateGoalDto
{
    [Required]
    public int userId { get; set; }


    [Required]
    public int Goal { get; set; }

    public int BooksRead { get; set; }

}

