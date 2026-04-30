namespace SkillPath.Services.Exceptions
{
    public class ValidationException : BaseException
    {
        public Dictionary<string, string[]> ValidationErrors { get; }

        public ValidationException(string message, Dictionary<string, string[]> validationErrors, object? details = null)
            : base(message, "VALIDATION_ERROR", 422, details)
        {
            ValidationErrors = validationErrors;
        }

        public ValidationException(Dictionary<string, string[]> validationErrors)
            : this("One or more validation errors occurred.", validationErrors)
        {
        }
    }
}
