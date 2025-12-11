using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs;

/// <summary>
/// Represents the Data Transfer Object (DTO) for updating a user's profile.
/// </summary>
/// <remarks>
/// This DTO is used to transfer data related to user profile updates between client and server.
/// It contains fields necessary to update user information such as username, email, name, and date of birth.
/// </remarks>
public class UpdateProfileDTO
{
    [Required] public string Username { get; set; }

    [Required]
    [MaxLength(100, ErrorMessage = "O email não pode ter mais de 100 caracteres.")]
    [EmailAddress(ErrorMessage = "Formato de email inválido.")]
    public string Email { get; set; }

    [Required] public string Nome { get; set; }

    [Required] public DateOnly Nascimento { get; set; }

    [Required] public String bio { get; set; }
}