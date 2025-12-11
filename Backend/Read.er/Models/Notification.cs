using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Read.er.Enumeracoes;
using Read.er.Models.Users;

namespace Read.er.Models;

/// <summary>
/// Represents a notification sent to a user.
/// </summary>
public class Notification
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    
    [Required] public int UserId { get; set; }
    [JsonIgnore] public User User { get; set; }

    [Required] 
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public NotificationType Type { get; set; }
    
    [Required]
    [MaxLength(100, ErrorMessage = "O comprimento não pode exceder os 100 caracteres.")]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(300, ErrorMessage = "O comprimento não pode exceder os 300 caracteres.")]
    public string Content { get; set; } = string.Empty;

    [Required] public DateTime DateCreated { get; set; } = DateTime.Now;
    
    [Required] public bool Read { get; set; } = false;
}