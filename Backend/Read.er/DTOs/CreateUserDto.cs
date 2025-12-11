using System;
using System.ComponentModel.DataAnnotations;
using Read.er.Enumeracoes;

namespace Read.er.DTOs
{
    /// <summary>
    /// Represents the data transfer object used for creating a new user.
    /// </summary>
    public class CreateUserDto
    {
        [Required]
        [MaxLength(50)]
        public string Username { get; set; }

        [Required]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; }

        [Required]
        [MaxLength(250)]
        public string Password { get; set; }

        [Required]
        [MaxLength(150)]
        public string Nome { get; set; }

        [Required]
        public DateOnly Nascimento { get; set; }

        [Required]
        public Role Role { get; set; }

        public string Bio { get; set; }

    }

}

