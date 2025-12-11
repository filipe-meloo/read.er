using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs.Wishlist;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models.Book;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WishlistController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IGoogleBooksService _googleBooksService;
    private readonly ITokenService _tokenService;

    public WishlistController(AppDbContext context, IGoogleBooksService googleBooksService, ITokenService tokenService)
    {
        _context = context;
        _googleBooksService = googleBooksService;
        _tokenService = tokenService;
    }

    /// <summary>
    /// Adds a specified sale trade item to the authenticated user's wishlist.
    /// </summary>
    /// <param name="model">The data transfer object containing the SaleTradeId to be added to the wishlist.</param>
    /// <returns>
    /// An asynchronous operation that returns an IActionResult indicating the result of the operation:
    /// <list type="bullet">
    /// <item>
    /// <term>Ok</term>
    /// <description>If the item is successfully added to the wishlist.</description>
    /// </item>
    /// <item>
    /// <term>NotFound</term>
    /// <description>If the user or the sale trade item is not found.</description>
    /// </item>
    /// <item>
    /// <term>Forbid</term>
    /// <description>If the user role does not allow adding items or the sale trade owner is not a friend.</description>
    /// </item>
    /// <item>
    /// <term>Conflict</term>
    /// <description>If the item is already present in the wishlist.</description>
    /// </item>
    /// <item>
    /// <term>BadRequest</term>
    /// <description>If the user attempts to add their own sale trade item to the wishlist.</description>
    /// </item>
    /// </list>
    /// </returns>
    [HttpPost("addToWishlist")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> AddToWishlist([FromBody] AddToWishlistDto model)
    {
        var userId = _tokenService.GetUserIdByToken();

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return NotFound("Utilizador não encontrado.");

        if (user.Role == Role.Autor)
            return Forbid("Utilizadores com o papel de AUTOR não podem adicionar itens à Wishlist.");

        var saleTrade = await _context.SaleTrades.FindAsync(model.SaleTradeId);
        if (saleTrade == null)
            return NotFound("Venda ou troca não encontrada.");

        if (saleTrade.IdUser == userId)
            return BadRequest("Não pode adicionar o seu próprio anúncio à Wishlist.");

        var isFriend = await _context.UserFriendship.AnyAsync(uf =>
            uf.IsConfirmed &&
            ((uf.RequesterId == userId && uf.ReceiverId == saleTrade.IdUser) ||
             (uf.RequesterId == saleTrade.IdUser && uf.ReceiverId == userId)));

        if (!isFriend)
            return Forbid("Apenas itens de amigos podem ser adicionados à Wishlist.");

        var existingWishlistItem = await _context.Wishlists
            .FirstOrDefaultAsync(w => w.UserId == userId && w.SaleTradeId == model.SaleTradeId);

        if (existingWishlistItem != null)
            return Conflict("Já adicionou este item à Wishlist.");

        var wishlistItem = new Wishlist
        {
            UserId = userId,
            SaleTradeId = model.SaleTradeId,
            DateAdded = DateTime.UtcNow
        };

        _context.Wishlists.Add(wishlistItem);
        await _context.SaveChangesAsync();

        return Ok("Item adicionado à Wishlist.");
    }

    /// <summary>
    /// Retrieves the authenticated user's wishlist containing the details of each item.
    /// </summary>
    /// <returns>
    /// An asynchronous operation that returns an IActionResult containing the result of the operation:
    /// <list type="bullet">
    /// <item>
    /// <term>Ok</term>
    /// <description>A list of WishlistItemDto objects representing the items in the wishlist if any exist.</description>
    /// </item>
    /// <item>
    /// <term>NotFound</term>
    /// <description>If no items are found in the wishlist.</description>
    /// </item>
    /// </list>
    /// </returns>
    [HttpGet("list")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> GetWishlist()
    {
        var userId = _tokenService.GetUserIdByToken();

        var wishlistItems = await _context.Wishlists
            .Where(w => w.UserId == userId)
            .ToListAsync();

        if (!wishlistItems.Any())
            return NotFound("Nenhum item encontrado na wishlist.");

        var wishlistDetails = new List<WishlistItemDto>();

        foreach (var item in wishlistItems)
        {
            var saleTrade = await _context.SaleTrades.FirstOrDefaultAsync(st => st.Id == item.SaleTradeId);
            if (saleTrade == null)
                continue;

            var bookDetails = await _googleBooksService.FetchBookDetailsByIsbn(saleTrade.Isbn);

       
            var seller = await _context.Users
                .Where(u => u.Id == saleTrade.IdUser)
                .Select(u => u.Username)
                .FirstOrDefaultAsync() ?? "Nome do vendedor desconhecido";

            wishlistDetails.Add(new WishlistItemDto
            {
                SaleTradeId = saleTrade.Id,
                ISBN = saleTrade.Isbn,
                Title = bookDetails?.Title ?? "Título não encontrado",
                Author = bookDetails?.Author ?? "Autor desconhecido",
                Price = saleTrade.Price,
                SellerName = seller,
                State = saleTrade.State,
                Description = saleTrade.Notes,
                Photo1 = null,
                Photo2 = null,
                DateAdded = item.DateAdded,
                DesiredBookISBN = saleTrade.IsbnDesiredBook


            });
        }

        return Ok(wishlistDetails);
    }

    /// <summary>
    /// Removes a specified sale trade item from the authenticated user's wishlist.
    /// </summary>
    /// <param name="model">The data transfer object containing the SaleTradeId to be removed from the wishlist.</param>
    /// <returns>
    /// An asynchronous operation that returns an IActionResult indicating the result of the operation:
    /// <list type="bullet">
    /// <item>
    /// <term>Ok</term>
    /// <description>If the item is successfully removed from the wishlist.</description>
    /// </item>
    /// <item>
    /// <term>NotFound</term>
    /// <description>If the sale trade item is not found in the user's wishlist.</description>
    /// </item>
    /// </list>
    /// </returns>
    [HttpDelete("remove")]
    [Authorize(Roles = "Leitor")]
    public async Task<IActionResult> RemoveFromWishlist([FromBody] AddToWishlistDto model)
    {
        var userId = _tokenService.GetUserIdByToken();

        var wishlistItem = await _context.Wishlists
            .FirstOrDefaultAsync(w => w.UserId == userId && w.SaleTradeId == model.SaleTradeId);

        if (wishlistItem == null)
            return NotFound("Venda não encontrada na lista de desejos.");

        _context.Wishlists.Remove(wishlistItem);
        await _context.SaveChangesAsync();

        return Ok("Venda removida da lista de desejos.");
    }
}
