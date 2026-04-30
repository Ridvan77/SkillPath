namespace SkillPath.Services.DTOs.Notification
{
    public record NotificationDto(
        Guid Id,
        string Title,
        string Content,
        string? ImageUrl,
        string Type,
        bool IsRead,
        DateTime CreatedAt,
        string? RelatedEntityId,
        string? RelatedEntityType
    );
}
