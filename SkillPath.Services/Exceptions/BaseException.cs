namespace SkillPath.Services.Exceptions
{
    public abstract class BaseException : Exception
    {
        public string ErrorCode { get; }
        public int StatusCode { get; }
        public object? Details { get; }

        protected BaseException(string message, string errorCode, int statusCode, object? details = null)
            : base(message)
        {
            ErrorCode = errorCode;
            StatusCode = statusCode;
            Details = details;
        }
    }
}
