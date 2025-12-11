using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Read.er.Data;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using Read.er.Enumeracoes.Post;
using Stripe.Forwarding;

namespace Read.er.Controllers.Metrics
{
    [ApiController]
    [Route("api/admin")]
    [Authorize(Roles = "Admin")]
    public class MetricsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MetricsController(AppDbContext context)
        {
            _context = context;
        }


        
        /// <summary>
        /// Retrieves various metrics based on the specified list of metric names.
        /// </summary>
        /// <param name="metrics">A list of metric names to retrieve. Valid options include:
        /// "totalUsers", "totalCachedBooks", "totalDailyPosts", "totalInteractions",
        /// "reportedPosts", "solvedReportedPosts", "percentageSolvedReportedPosts",
        /// "mostActiveUsers", and "mostPopularCommunities".</param>
        /// <returns>An IActionResult containing a dictionary of the requested metrics
        /// and their corresponding values, or a BadRequest if no valid metrics were specified.</returns>
        [HttpGet("metrics")]
        public async Task<IActionResult> GetMetrics([FromQuery] List<string> metrics)
        {
            // Initialize the dictionary to store metrics results
            var response = new Dictionary<string, object>();

            // Define metric constants
            const string sTotalUsers = "totalUsers";
            const string sTotalCachedBooks = "totalCachedBooks";
            const string sTotalDailyPosts = "totalDailyPosts";
            const string sTotalInteractions = "totalInteractions";
            const string sReportedPosts = "reportedPosts";
            const string sSolvedReportedPosts = "solvedReportedPosts";
            const string sPercentageSolvedReportedPosts = "percentageSolvedReportedPosts";
            const string sMostActiveUsers = "mostActiveUsers";
            const string sMostPopularCommunities = "mostPopularCommunities";

            // Iterate over requested metrics
            foreach (var metric in metrics)
            {
                // Calculate the time 24 hours ago for filtering
                var twentyFourHoursAgo = DateTime.UtcNow.AddHours(-24);

                switch (metric)
                {
                    case sTotalUsers:
                        // Count total users
                        var totalUsers = await _context.Users.CountAsync();
                        response.Add(sTotalUsers, totalUsers);
                        break;
                    case sTotalCachedBooks:
                        // Count total cached books
                        var totalCachedBooks = await _context.CachedBooks.CountAsync();
                        response.Add(sTotalCachedBooks, totalCachedBooks);
                        break;
                    case sTotalDailyPosts:
                        // Count posts created in the last 24 hours
                        var totalDailyPosts = await _context.Posts
                            .Where(p => p.DataCriacao >= twentyFourHoursAgo)
                            .CountAsync();
                        response.Add(sTotalDailyPosts, totalDailyPosts);
                        break;
                    case sTotalInteractions:
                        // Count likes and comments in the last 24 hours
                        var totalLikes24Hours = await _context.PostReactions
                            .Where(p => p.ReactionDate >= twentyFourHoursAgo)
                            .Where(p => p.ReactionType == ReactionType.Like)
                            .CountAsync();
                        var totalComments24Hours = await _context.Comments
                            .Where(p => p.CreatedAt >= twentyFourHoursAgo)
                            .CountAsync();
                        response.Add(sTotalInteractions, totalLikes24Hours + totalComments24Hours);
                        break;
                    case sReportedPosts:
                        // Count reported posts
                        var reportedPosts = await _context.Posts.Where(p => p.IsReported).CountAsync();
                        response.Add(sReportedPosts, reportedPosts);
                        break;
                    case sSolvedReportedPosts:
                        // Count reported posts marked as inappropriate
                        var solvedReportedPosts = await _context.Posts.Where(p => p.IsReported && p.IsInappropriate).CountAsync();
                        response.Add(sSolvedReportedPosts, solvedReportedPosts);
                        break;
                    case sPercentageSolvedReportedPosts:
                        // Calculate percentage of reported posts that are solved
                        var percentageSolvedReportedPosts = await _context.Posts.Where(p => p.IsReported && p.IsInappropriate).CountAsync();
                        var totalReportedPosts = await _context.Posts.Where(p => p.IsReported).CountAsync();
                        response.Add(sPercentageSolvedReportedPosts, (double)percentageSolvedReportedPosts / totalReportedPosts);
                        break;
                    case sMostActiveUsers:
                        // Find top 10 most active users by post count
                        var mostActiveUsers = await _context.Users
                            .Select(u => new 
                            { 
                                Id = u.Id, 
                                TotalPosts = u.Posts.Count 
                            })
                            .OrderByDescending(u => u.TotalPosts)
                            .Take(10)
                            .ToListAsync();

                        response.Add(sMostActiveUsers, mostActiveUsers);
                        break;
                    case sMostPopularCommunities:
                        // Find top 10 most popular communities by member count
                        var mostPopularCommunities = await _context.Communities
                            .Select(c => new 
                            { 
                                Id = c.Id, 
                                TotalMembers = c.Members.Count 
                            })
                            .OrderByDescending(c => c.TotalMembers)
                            .Take(10)
                            .ToListAsync();

                        response.Add(sMostPopularCommunities, mostPopularCommunities);
                        break;
                } 
            }
            
            // Check if any metrics were added to the response
            if (!response.Any())
            {
                return BadRequest("No valid metrics specified.");
            }
            
            return Ok(response);
        }
    }
}
