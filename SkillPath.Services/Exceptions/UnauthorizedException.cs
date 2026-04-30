namespace SkillPath.Services.Exceptions
{
    public class UnauthorizedException : BaseException
    {
        public UnauthorizedException(string message, object? details = null)
            : base(message, "UNAUTHORIZED", 401, details)
        {
        }
    }
}
