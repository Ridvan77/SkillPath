namespace SkillPath.Services.DTOs.Auth
{
    public record AuthResponse(
        string UserId,
        string FirstName,
        string LastName,
        string Email,
        List<string> Roles,
        string AccessToken,
        string RefreshToken,
        DateTime TokenExpiration
    );
}
