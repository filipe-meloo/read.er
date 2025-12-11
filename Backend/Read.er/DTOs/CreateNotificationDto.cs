using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs;

/// <summary>
/// Represents a Data Transfer Object (DTO) for creating a notification.
/// </summary>
/// <remarks>
/// This class is used to encapsulate the necessary data for creating a notification,
/// ensuring all required fields are present and validated during the creation process.
/// </remarks>
public class CreateNotificationDto
{
    [Required] public int UserId { get; set; }

    [Required] public NotificationType Type { get; set; }
    [Required] public string Title { get; set; }
    [Required] public string Content { get; set; }
}