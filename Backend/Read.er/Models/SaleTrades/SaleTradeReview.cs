using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Read.er.Models.Users;

namespace Read.er.Models.SaleTrades;

/// <summary>
/// Represents a review for a sale trade in the system.
/// </summary>
public class SaleTradeReview
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int SellerId { get; set; }
    [JsonIgnore]
    public User Seller { get; set; }

    [Required]
    public int ReviewerId { get; set; }

    [JsonIgnore]
    public User Reviewer { get; set; }

    [Required]
    public int TradeOfferId { get; set; }

    [JsonIgnore]
    public SaleTradeOffer TradeOffer { get; set; }

    [Required]
    [Range(1, 5)]
    public int Rating { get; set; }

    [Required]
    [MaxLength(300, ErrorMessage = "O comprimento do comentário não pode exceder 300 caracteres.")]
    public string Comment { get; set; } = string.Empty;

    public DateTime DateReviewed { get; set; } = DateTime.UtcNow;
}
