using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;

namespace Read.er.Models.Book;

/// <summary>
/// Represents a wishlist that contains items a user is interested in purchasing or trading.
/// </summary>
public class Wishlist
{
    [Required] public int UserId { get; set; }
    public User User { get; set; }
    
    [Required] public int SaleTradeId { get; set; }
    public SaleTrade SaleTrade { get; set; }

    public DateTime DateAdded { get; set; } = DateTime.Now;
}