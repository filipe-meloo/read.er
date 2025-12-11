using Microsoft.AspNetCore.Mvc;
using Read.er.Data;
using Read.er.Services;

namespace Read.er.Controllers.WebSockets;

public class WebSocketController : ControllerBase
{
    private readonly WsManager _wsManager;

    /// <summary>
    /// A controller for handling WebSocket requests and managing WebSocket connections.
    /// </summary>
    public WebSocketController(WsManager wsManager)
    {
        _wsManager = wsManager;
    }

    /// <summary>
    /// Handles incoming WebSocket requests for notifications.
    /// Establishes a WebSocket connection if the request is valid.
    /// Retrieves the user ID from the API using the provided token,
    /// adds the user's WebSocket to the manager, and processes WebSocket communication.
    /// </summary>
    /// <remarks>
    /// Responds with a 401 status code if the token is invalid or an exception occurs.
    /// Responds with a 400 status code if the request is not a valid WebSocket request.
    /// </remarks>
    /// <returns>An asynchronous task representing the operation.</returns>
    [HttpGet]
    [Route("/ws/notifications")]
    public async Task Get()
    {
        if (HttpContext.WebSockets.IsWebSocketRequest)
        {
            var token = HttpContext.Request.Query["token"].ToString();
            Console.WriteLine(token);
            
            try
            {
                var userId = await _wsManager.GetUserIdFromApi(token);
                
                var webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();
                _wsManager.AddSocket(userId, webSocket);

                await WebSocketHandlingMiddleware.HandleWebSocketAsync(webSocket, userId, _wsManager);
            }
            catch (Exception ex)
            {
                HttpContext.Response.StatusCode = 401; // Unauthorized
                await HttpContext.Response.WriteAsync($"Unauthorized: {ex.Message}");
            }
        }
        else
        {
            HttpContext.Response.StatusCode = 400; // Bad Request
        }
    }
}