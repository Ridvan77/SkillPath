namespace SkillPath.Services.DTOs.Review
{
    public record ReviewDto(
        Guid Id,
        string UserId,
        string UserFullName,
        Guid CourseId,
        int Rating,
        string Comment,
        DateTime CreatedAt,
        bool IsVisible,
        int HelpfulCount,
        bool IsHelpfulByCurrentUser
    );
}
