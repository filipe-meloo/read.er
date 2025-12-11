using Read.er.Enumeracoes;

namespace Read.er.DTOs.Wishlist;

/// <summary>
/// Represents a data transfer object for a wishlist item in a book trading application.
/// </summary>
public class WishlistItemDto
{
    public int SaleTradeId { get; set; }
    public string ISBN { get; set; }
    public string Title { get; set; }
    public int IdUser { get; set; }
    public string Author { get; set; }
    public decimal? Price { get; set; }
    public string SellerName { get; set; }
    public BookState State { get; set; }
    public string Description { get; set; }
    public string Photo1 { get; set; }
    public string Photo2 { get; set; }
    public DateTime DateAdded { get; set; }
    public string DesiredBookISBN { get; set; }
}

