namespace SkillPath.Services.DTOs.News
{
    public record NewsDto(
        Guid Id,
        string Title,
        string Content,
        string? ImageUrl,
        DateTime CreatedAt,
        string CreatedByName
    );
}
