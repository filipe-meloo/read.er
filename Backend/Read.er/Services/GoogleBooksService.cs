using System;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using Read.er.DTOs.LibraryBook;
using Read.er.Interfaces;
using Microsoft.Extensions.Configuration;
using System.Linq;
using Read.er.Enumeracoes;
using Newtonsoft.Json;

using Read.er.Models.Book;

using Read.er.Models;
using Read.er.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace Read.er.Services
{
    public class GoogleBooksService : IGoogleBooksService
    {
        private readonly string _apiKey;
        private readonly HttpClient _httpClient;

        public GoogleBooksService(IConfiguration configuration)
        {
            _apiKey = configuration["GoogleBooksApi:ApiKey"] ?? throw new ArgumentNullException(nameof(configuration));
            _httpClient = new HttpClient();
        }

        public async Task<JObject> GetBookByIsbnAsync(string isbn)
        {
            try
            {
                var url = $"https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}&key={_apiKey}";
                var response = await _httpClient.GetStringAsync(url);
                return JObject.Parse(response);
            }
            catch (Exception)
            {
                return null;
            }
        }
        
        public async Task<string> GetIsbnByTitle(string title)
        {
            try
            {
                var response = await _httpClient.GetStringAsync($"https://www.googleapis.com/books/v1/volumes?q=intitle:{title}&key={_apiKey}");
                var data = JObject.Parse(response);

                var isbn = data["items"]?[0]?["volumeInfo"]?["industryIdentifiers"]?
                    .FirstOrDefault(id => id["type"].ToString() == "ISBN_13")?["identifier"].ToString();

                return isbn ?? "ISBN não encontrado";
            }
            catch (Exception)
            {
                return "Erro ao buscar ISBN";
            }
        }
        
        public async Task<LibraryBookDto> FetchBookDetailsByIsbn(string isbn)
        {
            var bookData = await GetBookByIsbnAsync(isbn);
            if (bookData == null || bookData["totalItems"].ToObject<int>() == 0)
            {
                return null;
            }

            // Extraia o id do volume (volumeId)
            var volumeId = bookData["items"][0]["id"]?.ToString() ?? string.Empty;

            var volumeInfo = bookData["items"][0]["volumeInfo"];

            var genres = volumeInfo["categories"]?.Select(c => c.ToString()).ToList();
            var imageLinks = volumeInfo["imageLinks"];

            // Obtenha a URL da miniatura (thumbnail)
            string thumbnailUrl = imageLinks?["thumbnail"]?.ToString() ?? string.Empty;

            return new LibraryBookDto
            {
                Isbn = isbn,
                Title = volumeInfo["title"]?.ToString() ?? "Título desconhecido",
                Author = volumeInfo["authors"] != null ? string.Join(", ", volumeInfo["authors"].Select(a => a.ToString())) : "Autor desconhecido",
                Description = volumeInfo["description"]?.ToString(),
                PublishDate = DateTime.TryParse(volumeInfo["publishedDate"]?.ToString(), out var publishDate) ? publishDate : (DateTime?)null,
                Genre = genres != null ? string.Join(", ", genres) : "Gênero desconhecido", // Preenche com os gêneros
                Status = Status.Tbr,
                Length = volumeInfo["pageCount"]?.ToObject<int>() ?? 0,
                PagesRead = 0,
                PercentageRead = 0,
                CoverUrl = thumbnailUrl,
                VolumeId = volumeId // Agora atribuímos corretamente o volumeId
            };
        }
        
        public async Task<string?> GetTitleByIsbn(string isbn)
        {
            try
            {
                var response = await _httpClient.GetAsync($"https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}");
                response.EnsureSuccessStatusCode();

                var content = await response.Content.ReadAsStringAsync();
                var bookData = JsonConvert.DeserializeObject<GoogleBooksResponse>(content);

                return bookData?.Items?.FirstOrDefault()?.VolumeInfo?.Title ?? "Título não disponível";
            }
            catch (HttpRequestException ex)
            {
                return "Erro de rede";
            }
            catch (Exception ex)
            {
                return "Erro desconhecido";
            }
        }
        
        
        public async Task<List<SearchBookDto>> SearchGoogleBooksByTitleAsync(string title)
        {
            var requestUrl = $"https://www.googleapis.com/books/v1/volumes?q=intitle:{title}&key={_apiKey}";

            try
            {
                var response = await _httpClient.GetAsync(requestUrl);
                response.EnsureSuccessStatusCode();

                var jsonResponse = await response.Content.ReadAsStringAsync();
                var googleBooksResponse = JsonConvert.DeserializeObject<GoogleBooksResponse>(jsonResponse);

                var books = googleBooksResponse?.Items?.Select(item => new SearchBookDto
                {
                    Title = item.VolumeInfo.Title ?? "Título desconhecido",
                    Description = item.VolumeInfo.Description ?? "Descrição não disponível",
                    Author = item.VolumeInfo.Authors != null
                        ? string.Join(", ", item.VolumeInfo.Authors)
                        : "Autor desconhecido",
                    ISBN = item.VolumeInfo.IndustryIdentifiers?.FirstOrDefault()?.Identifier ?? "ISBN não disponível",
                    Genre = item.VolumeInfo.Categories != null
                        ? string.Join(", ", item.VolumeInfo.Categories)
                        : "Gênero desconhecido",
                    Length = item.VolumeInfo.PageCount ?? 0,
                    CoverUrl = item.VolumeInfo.ImageLinks != null
                        ? item.VolumeInfo.ImageLinks.Thumbnail
                        : string.Empty,
                    VolumeId = item.Id ?? string.Empty
                }).ToList();

                return books;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao buscar livros da Google Books API: {ex.Message}");
                return null; // Retorna null ou uma lista vazia, conforme necessário
            }
        }
        

        // Support classes
        public class GoogleBooksResponse
        {
            public List<GoogleBookItem> Items { get; set; }
        }

        public class GoogleBookItem
        {
            public VolumeInfo VolumeInfo { get; set; }
            public string Id { get; set; } // Certifica-te de incluir o Id aqui
        }

        public class VolumeInfo
        {
            public string Title { get; set; }
            public string Description { get; set; }
            public List<string> Authors { get; set; }
            public List<IndustryIdentifier> IndustryIdentifiers { get; set; }
            public List<string> Categories { get; set; }
            public int? PageCount { get; set; } // Use int? para permitir valores nulos
            public ImageLinks ImageLinks { get; set; } // Adiciona a propriedade ImageLinks
        }

        public class ImageLinks
        {
            public string Thumbnail { get; set; }
        }

        public class IndustryIdentifier
        {
            public string Type { get; set; }
            public string Identifier { get; set; }
        }
    }
}
