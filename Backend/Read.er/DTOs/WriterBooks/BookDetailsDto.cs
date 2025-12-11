namespace Read.er.DTOs.WriterBooks;

public class BookDetailsDto
{
    public int Id { get; set; } // ID único do livro no banco de dados
    public string ISBN { get; set; }
    public string Title { get; set; } // Título do livro
    public string Author { get; set; } // Autor do livro
    public string CoverUrl { get; set; } // URL da capa do livro
    public string VolumeId { get; set; } // ID do volume, normalmente vindo do Google Books API
    public string Description { get; set; }
}


