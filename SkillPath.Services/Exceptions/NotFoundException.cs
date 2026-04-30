namespace SkillPath.Services.Exceptions
{
    public class NotFoundException : BaseException
    {
        public NotFoundException(string message, object? details = null)
            : base(message, "NOT_FOUND", 404, details)
        {
        }
    }
}
