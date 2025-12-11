using System;
namespace Read.er.DTOs
{
	/// <summary>
	/// Data Transfer Object for facilitating the functionality of following an author.
	/// </summary>
	/// <remarks>
	/// This DTO contains the essential information required by the system to process
	/// a "follow" action, specifically associating a reader with an author.
	/// </remarks>
	public class FollowAuthorDto
	{
		public int LeitorId { get; set; }
		public int AuthorId { get; set; }
			
	}
}

