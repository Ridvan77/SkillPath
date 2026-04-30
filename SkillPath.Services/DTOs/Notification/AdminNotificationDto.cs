namespace SkillPath.Services.DTOs.Notification
{
    public record AdminNotificationDto(
        Guid Id,
        string Title,
        string Content,
        string? ImageUrl,
        string Type,
        string TargetGroup,
        int RecipientCount,
        string Status,
        DateTime? ScheduledAt,
        DateTime? SentAt,
        DateTime CreatedAt
    );
}
