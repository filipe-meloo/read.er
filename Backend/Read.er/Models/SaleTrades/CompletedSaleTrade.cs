using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Models.Book;
using Read.er.Models.Users;

namespace Read.er.Models.SaleTrades;

/// <summary>
/// Represents a completed sale trade of a book, capturing details of the transaction such as
/// the original sale trade ID, seller and buyer information, price, completion date,
/// and associated Stripe transaction details.
/// </summary>
public class CompletedSaleTrade : BookBase
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int OriginalSaleTradeId { get; set; }

    [Required] public int SellerId { get; set; }
    public User Seller { get; set; }

    [Required] public int BuyerId { get; set; }
    public User Buyer { get; set; }

    public decimal? Price { get; set; }

    [Required] public DateTime DateCompleted { get; set; } = DateTime.Now;

    [MaxLength(5000, ErrorMessage = "O comprimento não pode exceder os 5000 caracteres.")]
    public string StripeTransaction { get; set; } = string.Empty;
}