using SkillPath.Services.DTOs;
using SkillPath.Services.Exceptions;
using System.Text.Json;

namespace SkillPath.WebAPI.Middleware
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
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

        private async Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            var response = new ErrorResponse { Success = false };

            switch (exception)
            {
                case ValidationException validationEx:
                    response.StatusCode = validationEx.StatusCode;
                    response.Error = new ErrorDetail
                    {
                        ErrorCode = validationEx.ErrorCode,
                        Message = validationEx.Message,
                        ValidationErrors = validationEx.ValidationErrors
                    };
                    _logger.LogWarning("Validation error: {Message}", validationEx.Message);
                    break;

                case BaseException baseEx:
                    response.StatusCode = baseEx.StatusCode;
                    response.Error = new ErrorDetail
                    {
                        ErrorCode = baseEx.ErrorCode,
                        Message = baseEx.Message,
                        Details = baseEx.Details
                    };
                    _logger.LogWarning("Business error: {ErrorCode} - {Message}", baseEx.ErrorCode, baseEx.Message);
                    break;

                case UnauthorizedAccessException:
                    response.StatusCode = 401;
                    response.Error = new ErrorDetail
                    {
                        ErrorCode = "UNAUTHORIZED",
                        Message = "Nemate pristup ovom resursu."
                    };
                    _logger.LogWarning("Unauthorized access attempt");
                    break;

                default:
                    response.StatusCode = 500;
                    response.Error = new ErrorDetail
                    {
                        ErrorCode = "INTERNAL_ERROR",
                        Message = "Doslo je do greske na serveru."
                    };
                    _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);
                    break;
            }

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = response.StatusCode;

            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(response, options));
        }
    }
}
