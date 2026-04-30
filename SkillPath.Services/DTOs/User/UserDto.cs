namespace SkillPath.Services.DTOs.User
{
    public record UserDto(
        string Id,
        string FirstName,
        string LastName,
        string Email,
        string? PhoneNumber,
        string? ProfileImageUrl,
        int? CityId,
        string? CityName,
        List<string> Roles,
        bool IsActive,
        DateTime CreatedAt,
        DateTime? LastLoginAt,
        int ReservationCount
    );
}
