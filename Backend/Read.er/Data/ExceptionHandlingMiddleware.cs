using Microsoft.EntityFrameworkCore;

namespace Read.er.Data;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ExceptionHandlingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    /// <summary>
    /// Middleware method to handle exceptions during HTTP request processing.
    /// </summary>
    /// <param name="context">The current HTTP context.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    public async Task Invoke(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    /// <summary>
    /// Handles exceptions thrown during HTTP request processing and generates an appropriate JSON response.
    /// </summary>
    /// <param name="context">The current HTTP context.</param>
    /// <param name="exception">The exception that was thrown during request processing.</param>
    /// <returns>A task representing the asynchronous operation of handling the exception.</returns>
    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var response = context.Response;

        // Verifica se a resposta já foi iniciada
        if (response.HasStarted)
        {
            // Se já foi iniciada, não podemos modificar os headers ou enviar conteúdo
            return;
        }

        // Define o tipo de conteúdo e o status da resposta
        response.ContentType = "application/json";
        response.StatusCode = exception switch
        {
            ArgumentException => StatusCodes.Status400BadRequest,
            KeyNotFoundException => StatusCodes.Status404NotFound,
            DbUpdateException => StatusCodes.Status500InternalServerError,
            _ => StatusCodes.Status500InternalServerError
        };

        // Envia a resposta com os detalhes do erro
        var errorResponse = new
        {
            error = exception.Message,
            details = exception.Data?.ToString() ?? "No additional details"
        };

        // Serializa e escreve a resposta de forma assíncrona
        await response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(errorResponse));
    }

}