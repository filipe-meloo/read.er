using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using Read.er.Enumeracoes;

namespace Read.er.Models.SaleTrades;

/// <summary>
/// Represents a sale or trade offer for a book in the system.
/// This class is used to manage the details and availability of a book for sale or trade by a user.
/// </summary>
public class SaleTrade
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int IdUser { get; set; }

    [Required]
    [MaxLength(13)]
    [RegularExpression("(.{10}|.{13})", ErrorMessage = "Comprimento deve ser 10 ou 13.")]
    public string Isbn { get; set; } = string.Empty;

    public decimal? Price { get; set; }

    public bool IsAvailableForSale { get; set; }
    public bool IsAvailableForTrade { get; set; }

    [Required]
    public BookState State { get; set; }

    [MaxLength(500, ErrorMessage = "O comprimento não pode exceder os 500 caracteres.")]
    public string? Notes { get; set; }

    [MaxLength(13)]
    [RegularExpression("(.{10}|.{13})", ErrorMessage = "Comprimento deve ser 10 ou 13.")]
    public string? IsbnDesiredBook { get; set; }

    [Required]
    public DateTime DateCreation { get; set; } = DateTime.UtcNow;

    // Adicionar título do livro
    [MaxLength(80, ErrorMessage = "O comprimento não pode exceder os 80 caracteres.")]
    public string Title { get; set; } = string.Empty;

    public string? DesiredBookTitle { get; set; } = string.Empty;


    [JsonIgnore]
    public ICollection<SaleTradeOffer> Offers { get; set; } = new List<SaleTradeOffer>();
}
