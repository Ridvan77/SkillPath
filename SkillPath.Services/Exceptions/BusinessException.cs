namespace SkillPath.Services.Exceptions
{
    public class BusinessException : BaseException
    {
        public BusinessException(string message, object? details = null)
            : base(message, "BUSINESS_ERROR", 400, details)
        {
        }
    }
}
