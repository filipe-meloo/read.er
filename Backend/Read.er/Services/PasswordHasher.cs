using System.Security.Cryptography;

namespace Read.er.Services;

public class PasswordHasher
{
    /// <summary>
    /// Hashes the specified password using a cryptographic hashing algorithm combined with a unique salt.
    /// </summary>
    /// <param name="password">The password to be hashed.</param>
    /// <returns>A base64-encoded string representing the hashed password, including the salt used in the hashing process.</returns>
    public string HashPassword(string password)
    {
        var salt = new byte[16];
        using (var rng = new RNGCryptoServiceProvider())
        {
            rng.GetBytes(salt);
        }

        var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000);
        var hash = pbkdf2.GetBytes(20);

        var hashBytes = new byte[36];
        Array.Copy(salt, 0, hashBytes, 0, 16);
        Array.Copy(hash, 0, hashBytes, 16, 20);
        return Convert.ToBase64String(hashBytes);
    }

    /// <summary>
    /// Verifies the specified password against the stored hash to determine if they match.
    /// </summary>
    /// <param name="password">The password to verify.</param>
    /// <param name="storedHash">The base64-encoded password hash with salt used for verification.</param>
    /// <returns>True if the password matches the stored hash; otherwise, false.</returns>
    public bool VerifyPassword(string password, string storedHash)
    {
        var hashBytes = Convert.FromBase64String(storedHash);
        var salt = new byte[16];
        Array.Copy(hashBytes, 0, salt, 0, 16);

        var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000);
        var hash = pbkdf2.GetBytes(20);

        for (var i = 0; i < 20; i++)
            if (hashBytes[i + 16] != hash[i])
                return false;

        return true;
    }
}