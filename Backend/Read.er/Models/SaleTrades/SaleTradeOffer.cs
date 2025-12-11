using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;


namespace Read.er.Models.SaleTrades;

/// <summary>
/// Represents a sale trade offer made by a user.
/// </summary>
public class SaleTradeOffer
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int IdOffer { get; set; }

    [Required] public int IdUser { get; set; }

    [Required] 
    [MaxLength(13)]
    [RegularExpression("(.{10}|.{13})", ErrorMessage = "Comprimento deve ser 10 ou 13.")]
    public string IsbnOfferedBook { get; set; } = string.Empty;
    
    [MaxLength(300, ErrorMessage = "O comprimento não pode exceder os 300 caracteres.")]
    public string Message { get; set; } = string.Empty;
    public DateTime DateOffered { get; set; } = DateTime.UtcNow;

    public bool Declined { get; set; } = false;

    // Relacionamento com SaleTrade
    public int IdSaleTrade { get; set; }

    [JsonIgnore]
    public SaleTrades.SaleTrade SaleTrade { get; set; }
}