namespace SkillPath.Services.DTOs
{
    public class ErrorResponse
    {
        public bool Success { get; set; }
        public ErrorDetail Error { get; set; } = new();
        public int StatusCode { get; set; }
    }

    public class ErrorDetail
    {
        public string ErrorCode { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public object? Details { get; set; }
        public Dictionary<string, string[]>? ValidationErrors { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }
}
