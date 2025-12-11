namespace Read.er.Enumeracoes;

/// <summary>
/// Represents the different types of notifications that can be generated within the system.
/// </summary>
public enum NotificationType
{
    System,
    NewPost,
    PostLike,
    PostComment,
    MarketplaceTradeoffer,
    MarketplaceTradeAccepted,
    MarketplaceTradeRejected,
    MarketplaceNewSalePosted,
    MarketplaceNewTradePosted,
    MarketplaceNewSaleTradePosted,
    MarketplaceSaleCompleted,
    MarketplaceOfferReceived,
    FriendRequestReceived,
    FriendRequestAccepted,
    FriendRequestDeclined
}