using System.Net.Http.Headers;
using System.Net.WebSockets;
using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;

namespace Read.er.Services;

public class WsManager
{
    private readonly HttpClient _httpClient;
    private readonly ConcurrentDictionary<int, WebSocket> _sockets = new();
    
    /// <summary>
    /// Manages a collection of WebSockets associated with user IDs.
    /// </summary>
    /// <param name="httpClient">The HTTP client to use for sending requests to the API.</param>
    public WsManager(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    /// <summary>
    /// Adds a WebSocket to the manager for the given user ID.
    /// </summary>
    /// <param name="userId">The user ID to associate the WebSocket with.</param>
    /// <param name="socket">The WebSocket to add.</param>
    public void AddSocket(int userId, WebSocket socket) => _sockets[userId] = socket;

    /// <summary>
    /// Removes the WebSocket associated with the given user ID from the manager.
    /// </summary>
    /// <param name="userId">The ID of the user whose WebSocket is to be removed.</param>
    public void RemoveSocket(int userId) => _sockets.TryRemove(userId, out _);

    /// <summary>
    /// Retrieves the WebSocket associated with the given user ID from the manager, or <c>null</c> if no such WebSocket exists.
    /// </summary>
    /// <param name="userId">The ID of the user whose WebSocket is to be retrieved.</param>
    /// <returns>The WebSocket associated with <paramref name="userId"/>, or <c>null</c> if no such WebSocket exists.</returns>
    public WebSocket GetSocketByUserId(int userId) => _sockets.TryGetValue(userId, out var socket) ? socket : null;

    /// <summary>
    /// Sends the given message to the WebSocket associated with the given user ID,
    /// if such a WebSocket exists and is open.
    /// </summary>
    /// <param name="userId">The ID of the user to send the message to.</param>
    /// <param name="message">The message to send.</param>
    public async Task SendMessageToUser(int userId, string message)
    {
        var socket = GetSocketByUserId(userId);
        if (socket?.State == WebSocketState.Open)
        {
            var buffer = Encoding.UTF8.GetBytes(message);
            await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
        }
    }

    /// <summary>
    /// Retrieves the user ID associated with the given token from the API, or throws an exception if the token is invalid or the user ID cannot be retrieved.
    /// </summary>
    /// <param name="token">The token to use for authentication.</param>
    /// <returns>The user ID associated with the given token, or throws an exception if the token is invalid or the user ID cannot be retrieved.</returns>
    /// <exception cref="Exception">Thrown if the token is invalid or the user ID cannot be retrieved.</exception>
    public async Task<int> GetUserIdFromApi(string token)
    {
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _httpClient.GetAsync("https://reader-backendapi.azurewebsites.net/api/Auth/me");
        response.EnsureSuccessStatusCode();
        
        var userIdString = await response.Content.ReadAsStringAsync();
    
        // Deserializando o JSON em um Dictionary
        var jsonDict = JsonSerializer.Deserialize<Dictionary<string, string>>(userIdString);
    
        // Obtendo o valor de userID e convertendo para int
        if (jsonDict != null && jsonDict.TryGetValue("userId", out var userIdStr))
        {
            // Convertendo de string para int
            if (int.TryParse(userIdStr, out int userId))
            {
                return userId;
            }
        }

        throw new Exception("Failed to retrieve user ID from API.");
    }
}