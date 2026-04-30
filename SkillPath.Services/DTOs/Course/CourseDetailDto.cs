using SkillPath.Services.DTOs.CourseSchedule;

namespace SkillPath.Services.DTOs.Course
{
    public record CourseDetailDto(
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
        DateTime CreatedAt,
        string Description,
        List<CourseScheduleDto> Schedules
    );
}
