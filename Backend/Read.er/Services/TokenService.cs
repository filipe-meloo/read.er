using System.Security.Claims;
using Read.er.Interfaces;

namespace Read.er.Services;

public class TokenService : ITokenService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public TokenService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    /// <summary>
    /// Retrieves the user ID associated with the current token.
    /// </summary>
    /// <returns>
    /// The user ID extracted from the token.
    /// </returns>
    /// <exception cref="UnauthorizedAccessException">
    /// Thrown when the user ID is not found in the token.
    /// </exception>
    public int GetUserIdByToken()
    {
        if (_httpContextAccessor.HttpContext?.User.Identity is ClaimsIdentity identity)
        {
            var userIdClaim = identity.FindFirst("userId");
            if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var userId)) return userId;
        }

        throw new UnauthorizedAccessException("User ID not found in token.");
    }
}