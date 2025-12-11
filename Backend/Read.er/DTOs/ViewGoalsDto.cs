using System;
using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs
{
	/// <summary>
	/// Represents the data transfer object for viewing reading goals.
	/// </summary>
	public class ViewGoalsDto
	{
        public int Year { get; set; }
        public int Goal { get; set; }
        public int BooksRead { get; set; }
        public int RemainingBooks { get; set; }
    }
}

