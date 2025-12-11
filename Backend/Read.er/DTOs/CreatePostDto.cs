using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs;

/// <summary>
/// Data transfer object for creating a new post.
/// </summary>
/// <remarks>
/// This class encapsulates the attributes necessary to create and validate
/// a new post within the application. It requires content, publication type,
/// and book title, along with optional community and topic identifiers.
/// </remarks>
public class CreatePostDto
{
    [Required] public string Conteudo { get; set; }

    [Required] public TipoPublicacao TipoPublicacao { get; set; } // Crítica, Recomendação, Citação

    [Required] public string TituloLivro { get; set; }

    public int? IdCommunity { get; set; }
    public int? TopicId { get; set; }
}