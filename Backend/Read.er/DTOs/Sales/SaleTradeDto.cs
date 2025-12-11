using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs.Sales;

/// <summary>
/// Represents the data transfer object used for creating a sale or trade listing for a book.
/// </summary>
public class CreateSaleTradeDto
{
    [Required] public string Isbn { get; set; }

    public decimal? Price { get; set; }

    public bool IsAvailableForSale { get; set; }
    public bool IsAvailableForTrade { get; set; }

    public string? Title { get; set; }
    public string? DesiredBookTitle { get; set; }

    [Required] public BookState State { get; set; }

    public string Notes { get; set; }

    public string? IsbnDesiredBook { get; set; }
   
}

/// <summary>
/// Represents the data transfer object for creating a sale trade offer, including details of the book being offered and any accompanying message.
/// </summary>
public class CreateSaleTradeOfferDto
{
    public string IsbnOfferedBook { get; set; }
    public string Message { get; set; }
}

/// <summary>
/// Represents a data transfer object for a sale offer, containing the identifier of the associated sale trade.
/// </summary>
public class SaleOfferDto
{
    public int SaleTradeId { get; set; }
}

/// <summary>
/// Represents the data transfer object used to capture the decision on a sale or trade offer,
/// indicating whether the offer is accepted or declined, along with an accompanying message.
/// </summary>
public class SaleTradeOfferDecisionDto
{
    public bool Accept { get; set; }
    public string Message { get; set; }
}