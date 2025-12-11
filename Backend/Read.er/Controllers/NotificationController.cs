using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs;
using Read.er.Interfaces;
using Read.er.Models;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;

    public NotificationController(AppDbContext context, INotificationService notifcationService)
    {
        _context = context;
        _notificationService = notifcationService;
    }

    //POST: api/Notification
    /// <summary>
    /// Creates a new notification for a specified user based on the provided data.
    /// </summary>
    /// <param name="model">The data transfer object containing necessary details to create a notification.</param>
    /// <returns>An <see cref="IActionResult"/> indicating the result of the operation, including success status or error messages.</returns>
    [HttpPost]
    public async Task<IActionResult> PostNotification([FromBody] CreateNotificationDto model)
    {
        if (model == null)
            return BadRequest("Dados inválidos");

        if (!ModelState.IsValid)
            return BadRequest("Formato inválido.");

        if (await _context.Users.FindAsync(model.UserId) == null) return NotFound("Utilizador não encontrado.");

        try
        {
            var notification = await _notificationService.CreateNotificationAsync(model);

            return CreatedAtAction(nameof(PostNotification), new { id = notification.Id }, notification);
        }
        catch (Exception ex)
        {
            return StatusCode(500, "Erro ao processar o pedido");
        }
    }

    /// <summary>
    /// Marks the specified notification as read.
    /// </summary>
    /// <param name="id">The identifier of the notification to be marked as read.</param>
    /// <returns>An <see cref="IActionResult"/> indicating the result of the operation, including whether the notification was successfully marked as read.</returns>
    [HttpPatch("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var notification = await _context.Notifications.FindAsync(id);

        if (notification == null)
            return NotFound("Notificação não encontrada.");

        notification.Read = true;

        _context.Notifications.Update(notification);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    //Get: api/Notifications/{idNotification}
    /// <summary>
    /// Retrieves the notification with the specified identifier.
    /// </summary>
    /// <param name="id">The identifier of the notification to retrieve.</param>
    /// <returns>An <see cref="IActionResult"/> containing the notification data if found, or a not found response if the notification does not exist.</returns>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetNotification(int id)
    {
        var notification = await _context.Notifications.FindAsync(id);
        if (notification == null) return NotFound();
        return Ok(notification);
    }

    //GET: api/Notification/user/{userId}?qt={qt}
    //Obtem todas as notificacoes de um utilizador especifico
    /// <summary>
    /// Retrieves all notifications for a specific user, optionally limited to a specified quantity.
    /// </summary>
    /// <param name="userId">The unique identifier of the user whose notifications are to be retrieved.</param>
    /// <param name="qt">An optional parameter specifying the maximum number of notifications to return. If not specified, all notifications are returned.</param>
    /// <returns>An <see cref="IActionResult"/> containing the list of notifications, or a not found status if the user does not exist.</returns>
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetNotifications([FromRoute] int userId, [FromQuery] int? qt = null)
    {
        if (await _context.Users.FindAsync(userId) == null) return NotFound("Utilizador não encontrado.");


        var notificationsQuery = _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.DateCreated);


        if (qt.HasValue) notificationsQuery = notificationsQuery.Take(qt.Value) as IOrderedQueryable<Notification>;

        var notifications = await notificationsQuery.ToListAsync();
        return Ok(notifications);
    }
}