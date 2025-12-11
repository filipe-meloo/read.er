using System;
using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs.Sales;

/// <summary>
/// Represents the data transfer object used to create a checkout session.
/// </summary>
public class CreateCheckoutSessionDto
{
    [Required]
    public int SaleTradeId { get; set; }

}
