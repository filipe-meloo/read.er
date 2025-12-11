using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs.Community;

/// <summary>
/// Represents a data transfer object for posting content to a community.
/// </summary>
public class PostCommunityDto
{
    [Required] public int IdCommunity { get; set; }

    [Required] public string Conteudo { get; set; }

    [Required] public DateTime DataPublicacao { get; set; } = DateTime.Now;

    [Required] public TipoPublicacao Tipo { get; set; }

    [Required] public string ISBNLivro { get; set; }

    [Required] public int TopicId { get; set; }
}