namespace Read.er.Interfaces;

public interface ITokenService
{
    /// <summary>
    /// Retrieves the user ID associated with the current token.
    /// </summary>
    /// <returns>
    /// The user ID extracted from the token.
    /// </returns>
    int GetUserIdByToken();
}