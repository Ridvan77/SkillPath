namespace SkillPath.Services.Exceptions
{
    public class ForbiddenException : BaseException
    {
        public ForbiddenException(string message, object? details = null)
            : base(message, "FORBIDDEN", 403, details)
        {
        }
    }
}
