namespace SkillPath.Services.DTOs.Course
{
    public record CourseDto(
        Guid Id,
        string Title,
        string ShortDescription,
        decimal Price,
        int DurationWeeks,
        string DifficultyLevel,
        string? ImageUrl,
        bool IsActive,
        bool IsFeatured,
        int CategoryId,
        string CategoryName,
        string InstructorId,
        string InstructorName,
        double AverageRating,
        int ReviewCount,
        DateTime CreatedAt
    );
}
