namespace SkillPath.Services.DTOs.Category
{
    public record CategoryDto(
        int Id,
        string Name,
        string? Description,
        int CoursesCount
    );
}
