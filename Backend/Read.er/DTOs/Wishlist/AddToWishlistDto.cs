using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs.Wishlist;

/// <summary>
/// Represents the data transfer object for adding an item to a wishlist.
/// </summary>
public class AddToWishlistDto
{
    [Required] public int SaleTradeId { get; set; }
}