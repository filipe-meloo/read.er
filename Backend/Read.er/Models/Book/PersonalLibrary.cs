using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Enumeracoes;
using Read.er.Models.Users;

namespace Read.er.Models.Book;

/// <summary>
/// Represents a personal library entry for a user in the reading application.
/// </summary>
public class PersonalLibrary : BookBase
{
    [Required] public int UserId { get; set; }
    public User User { get; set; }

    [Required] public Status Status { get; set; }
    
    [Required] public int PagesRead { get; set; }

    public DateTime? DateRead { get; set; }
}