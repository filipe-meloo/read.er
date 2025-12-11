using System;
using Read.er.Enumeracoes;

namespace Read.er.DTOs
{
	/// <summary>
	/// Represents a data transfer object for user profiles.
	/// </summary>
	/// <remarks>
	/// The <c>UserProfileDTO</c> class contains information about a user's profile,
	/// including their username, real name, role, email, and date of birth.
	/// </remarks>
	public class UserProfileDTO
	{
		public String Username { get; set; }
		public String Nome { get; set; }
		public Role Role { get; set; }
		public String Email { get; set; }
		public DateOnly dbo { get; set; }
	}
}

