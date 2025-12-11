using System;
using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs
{
	/// <summary>
	/// Data Transfer Object for updating an existing reading goal.
	/// </summary>
	/// <remarks>
	/// This DTO is used to encapsulate the data required to update a reading goal
	/// within the application's reading management system.
	/// </remarks>
	public class UpdateGoalDto
	{
		[Required]
		public int newGoal { get; set; }
	}
}

