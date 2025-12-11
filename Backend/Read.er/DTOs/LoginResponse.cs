namespace Read.er.DTOs;

/// <summary>
/// Represents the response model for a login operation within the authentication system.
/// </summary>
/// <remarks>
/// This class contains the JWT token generated upon successful authentication.
/// The token is used for authorizing subsequent API requests.
/// </remarks>
public class LoginResponse
{
    public string Token { get; set; }
}