namespace Read.er.Models.SaleTrades;

/// <summary>
/// Represents configuration settings for Stripe integration.
/// </summary>
public class StripeSettings
{
    public string SecretKey { get; set; }
    public string PublishableKey { get; set; }
    public string WebhookSecret { get; set; }
}