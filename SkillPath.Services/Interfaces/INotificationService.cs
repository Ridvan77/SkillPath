using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Notification;

namespace SkillPath.Services.Interfaces;

public interface INotificationService
{
    Task<PagedResult<NotificationDto>> GetUserNotificationsAsync(string userId, bool? isRead, int page, int pageSize);
    Task<NotificationDto> CreateAsync(NotificationCreateRequest request);
    Task MarkAsReadAsync(Guid id, string userId);
    Task MarkAllAsReadAsync(string userId);
    Task<int> GetUnreadCountAsync(string userId);
    Task CreateSystemNotificationAsync(string userId, string title, string content, NotificationType type, string? relatedEntityId, string? relatedEntityType);
    Task<PagedResult<AdminNotificationDto>> GetAllNotificationsAsync(int page, int pageSize);
    Task<List<SentNotificationInfo>> SendScheduledNotificationsAsync();
    Task RescheduleAsync(Guid id, DateTime scheduledAt);
}

public record SentNotificationInfo(string Title, string Content, string TargetGroup);
