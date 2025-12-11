using Read.er.DTOs;
using Read.er.Enumeracoes.Post;
using Read.er.Models;

namespace Read.er.Interfaces;

public interface INotificationService
{
    /// <summary>
    /// Asynchronously creates a new notification based on the provided model.
    /// </summary>
    /// <param name="model">The data transfer object containing the necessary information to create a notification.</param>
    /// <returns>A task representing the asynchronous operation. The task result contains the created <see cref="Notification"/> object.</returns>
    Task<Notification> CreateNotificationAsync(CreateNotificationDto model);

    /// <summary>
    /// Notifies the friends of a specific user about a new post the user has created.
    /// </summary>
    /// <param name="userId">The ID of the user who created the post.</param>
    /// <param name="content">The content of the new post.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task NotifyFriendsOfNewPost(int userId, string content);

    /// <summary>
    /// Notifies community members of a new post created by a user, excluding the author of the post.
    /// </summary>
    /// <param name="communityId">The identifier of the community where the post was created.</param>
    /// <param name="userId">The identifier of the user who created the post.</param>
    /// <param name="content">The content of the new post.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task NotifyCommunityMembersOfNewPost(int communityId, int userId, string content);

    /// <summary>
    /// Notifies the author of a post about a new comment made by another user.
    /// </summary>
    /// <param name="postId">The identifier of the post that was commented on.</param>
    /// <param name="commenterId">The identifier of the user who made the comment.</param>
    /// <param name="commentContent">The content of the comment.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    Task NotifyAuthorOfComment(int postId, int commenterId, string commentContent);

    /// <summary>
    /// Notifies the author of a post about a new reaction.
    /// </summary>
    /// <param name="postId">The unique identifier of the post to which the reaction was made.</param>
    /// <param name="reactorId">The unique identifier of the user who reacted to the post.</param>
    /// <param name="reactionType">The type of reaction that was made on the post.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    Task NotifyAuthorOfReaction(int postId, int reactorId, ReactionType reactionType);

    /// <summary>
    /// Notifies the friends of a user about a new sale or trade offer available for a specific book.
    /// </summary>
    /// <param name="userId">The unique identifier of the user whose friends are to be notified.</param>
    /// <param name="isbn">The ISBN of the book that is available for sale or trade.</param>
    /// <param name="isAvailableForSale">Indicates whether the book is available for sale.</param>
    /// <param name="isAvailableForTrade">Indicates whether the book is available for trade.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task NotifyFriendsOfNewSale(int userId, string isbn, bool isAvailableForSale, bool isAvailableForTrade);

    /// <summary>
    /// Sends a notification to the seller when a new offer on a book has been received.
    /// </summary>
    /// <param name="sellerId">The unique identifier of the seller receiving the offer.</param>
    /// <param name="isbn">The International Standard Book Number of the book involved in the offer.</param>
    /// <param name="buyerName">The name of the buyer who made the offer.</param>
    /// <returns>A Task representing the asynchronous operation.</returns>
    Task NotifySellerOfNewOffer(int sellerId, string isbn, string buyerName);

    /// <summary>
    /// Sends a notification to the buyer indicating the completion of their purchase.
    /// </summary>
    /// <param name="buyerId">The identifier of the buyer who completed the purchase.</param>
    /// <param name="isbn">The ISBN of the item that was purchased.</param>
    /// <returns>A task that represents the asynchronous operation of notifying the buyer.</returns>
    Task NotifyBuyerOfPurchaseCompletion(int buyerId, string isbn);

    /// <summary>
    /// Notifies a buyer when a trade has been successfully completed.
    /// </summary>
    /// <param name="buyerId">The unique identifier of the buyer to be notified.</param>
    /// <param name="isbn">The ISBN of the book involved in the trade.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    Task NotifyBuyerOfTradeCompletion(int buyerId, string isbn);

    /// <summary>
    /// Notifies a seller that a sale has been successfully completed.
    /// </summary>
    /// <param name="sellerId">The unique identifier of the seller to be notified.</param>
    /// <param name="isbn">The International Standard Book Number of the sold book.</param>
    /// <returns>A task that represents the asynchronous operation of notifying the seller.</returns>
    Task NotifySellerOfSaleCompletion(int sellerId, string isbn);

    /// <summary>
    /// Notifies the seller about the completion of a trade for a specific book.
    /// </summary>
    /// <param name="sellerId">The unique identifier of the seller to be notified.</param>
    /// <param name="isbn">The International Standard Book Number (ISBN) of the book involved in the trade.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    Task NotifySellerOfTradeCompletion(int sellerId, string isbn);

    /// <summary>
    /// Sends a notification to a user informing them that their trade offer has been rejected.
    /// </summary>
    /// <param name="userId">The ID of the user who made the trade offer.</param>
    /// <param name="isbn">The International Standard Book Number (ISBN) of the book involved in the trade offer.</param>
    /// <returns>A task that represents the asynchronous operation of sending the notification.</returns>
    Task NotifyUserOfTradeRejection(int userId, string isbn);

    /// <summary>
    /// Sends a notification to the user when a book from their wishlist is sold and no longer available.
    /// </summary>
    /// <param name="userId">The identifier of the user whose wishlist item has been sold.</param>
    /// <param name="isbn">The International Standard Book Number of the book that was sold.</param>
    /// <returns>A task representing the asynchronous operation of sending the notification.</returns>
    Task NotifyUserOfWishlistSaleCompletion(int userId, string isbn);

    /// <summary>
    /// Notifies a user when a book from their wishlist has been successfully traded by someone else.
    /// </summary>
    /// <param name="userId">The unique identifier of the user to be notified.</param>
    /// <param name="isbn">The ISBN of the book that has been traded.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    Task NotifyUserOfWishlistTradeCompletion(int userId, string isbn);

    /// <summary>
    /// Sends a notification to a specific user.
    /// </summary>
    /// <param name="userId">The unique identifier of the user to whom the notification should be sent.</param>
    /// <param name="notification">The notification object containing details such as title, content, and type to be sent to the user.</param>
    /// <returns>A task representing the asynchronous operation of sending a notification to the specified user.</returns>
    Task SendNotificationToUser(int userId, Notification notification);
}