using System.Net.WebSockets;
using System.Text;
using Read.er.Services;

namespace Read.er.Data;

public static class WebSocketHandlingMiddleware
{
    /// <summary>
    /// Handles incoming WebSocket messages and sends responses back.
    /// </summary>
    /// <param name="webSocket">The WebSocket connection.</param>
    /// <param name="userId">The ID of the user who initiated the WebSocket connection.</param>
    /// <param name="wsManager">The WebSocket manager to use for removing the user's socket when the connection is closed.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    public static async Task HandleWebSocketAsync(WebSocket webSocket, int userId, WsManager wsManager)
    {
        var buffer = new byte[1024 * 4];

        try
        {
            while (webSocket.State == WebSocketState.Open)
            {
                var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await webSocket.CloseAsync(result.CloseStatus.Value, result.CloseStatusDescription, CancellationToken.None);
                    wsManager.RemoveSocket(userId);
                }
                else
                {
                    var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    Console.WriteLine($"Mensagem recebida: {message}");

                    var response = Encoding.UTF8.GetBytes($"Mensagem recebida: {message}");
                    await webSocket.SendAsync(new ArraySegment<byte>(response), WebSocketMessageType.Text, true, CancellationToken.None);
                }
            }
        }
        catch (Exception)
        {
            wsManager.RemoveSocket(userId);
        }
    }
}