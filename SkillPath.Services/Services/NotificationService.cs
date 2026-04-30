using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Notification;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Helpers;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<NotificationService> _logger;
        private readonly IRabbitMQPublisherService _rabbitMQPublisherService;

        public NotificationService(ApplicationDbContext context, ILogger<NotificationService> logger, IRabbitMQPublisherService rabbitMQPublisherService)
        {
            _context = context;
            _logger = logger;
            _rabbitMQPublisherService = rabbitMQPublisherService;
        }

        public async Task<PagedResult<NotificationDto>> GetUserNotificationsAsync(string userId, bool? isRead, int page, int pageSize)
        {
            var query = _context.Notifications
                .Where(n => n.UserId == userId)
                .AsQueryable();

            if (isRead.HasValue)
                query = query.Where(n => n.IsRead == isRead.Value);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NotificationDto(
                    n.Id,
                    n.Title,
                    n.Content,
                    n.ImageUrl,
                    n.Type.ToString(),
                    n.IsRead,
                    n.CreatedAt,
                    n.RelatedEntityId,
                    n.RelatedEntityType
                ))
                .ToListAsync();

            return new PagedResult<NotificationDto>(items, page, pageSize, totalCount);
        }

        public async Task<NotificationDto> CreateAsync(NotificationCreateRequest request)
        {
            var type = (NotificationType)request.Type;
            var targetGroup = request.TargetGroup ?? "all";

            // Determine status
            BroadcastStatus status;
            if (request.SaveAsDraft)
                status = BroadcastStatus.Draft;
            else if (request.ScheduledAt.HasValue)
                status = BroadcastStatus.Scheduled;
            else
                status = BroadcastStatus.Sent;

            // Create broadcast record
            var broadcast = new BroadcastNotification
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Content = request.Content,
                ImageUrl = request.ImageUrl,
                Type = type,
                TargetGroup = targetGroup,
                Status = status,
                ScheduledAt = request.ScheduledAt,
                CreatedAt = DateTime.UtcNow
            };

            // If sending immediately, deliver now
            if (status == BroadcastStatus.Sent)
            {
                var recipientCount = await SendBroadcastNowAsync(request);
                broadcast.RecipientCount = recipientCount;
                broadcast.SentAt = DateTime.UtcNow;
            }

            _context.BroadcastNotifications.Add(broadcast);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Broadcast notification '{Title}' created with status {Status}", request.Title, status);

            return new NotificationDto(
                broadcast.Id,
                broadcast.Title,
                broadcast.Content,
                broadcast.ImageUrl,
                type.ToString(),
                false,
                broadcast.CreatedAt,
                null,
                null
            );
        }

        public async Task<int> SendBroadcastNowAsync(NotificationCreateRequest request)
        {
            var type = (NotificationType)request.Type;
            var targetGroup = request.TargetGroup ?? "all";
            var userIds = await GetUserIdsByGroupAsync(targetGroup);

            foreach (var uid in userIds)
            {
                _context.Notifications.Add(new Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = uid,
                    Title = request.Title,
                    Content = request.Content,
                    ImageUrl = request.ImageUrl,
                    Type = type,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });
            }
            await _context.SaveChangesAsync();

            _logger.LogInformation("Notification sent to group '{Group}' ({Count} users)", targetGroup, userIds.Count);
            return userIds.Count;
        }

        public async Task<List<SentNotificationInfo>> SendScheduledNotificationsAsync()
        {
            var sent = new List<SentNotificationInfo>();

            var due = await _context.BroadcastNotifications
                .Where(n => n.Status == BroadcastStatus.Scheduled && n.ScheduledAt <= DateTime.UtcNow)
                .ToListAsync();

            foreach (var broadcast in due)
            {
                var request = new NotificationCreateRequest
                {
                    Title = broadcast.Title,
                    Content = broadcast.Content,
                    ImageUrl = broadcast.ImageUrl,
                    Type = (int)broadcast.Type,
                    TargetGroup = broadcast.TargetGroup,
                };

                var recipientCount = await SendBroadcastNowAsync(request);
                broadcast.Status = BroadcastStatus.Sent;
                broadcast.SentAt = DateTime.UtcNow;
                broadcast.RecipientCount = recipientCount;

                sent.Add(new SentNotificationInfo(broadcast.Title, broadcast.Content, broadcast.TargetGroup));
                _logger.LogInformation("Scheduled notification '{Title}' sent to {Count} users", broadcast.Title, recipientCount);
            }

            if (due.Any())
                await _context.SaveChangesAsync();

            return sent;
        }

        public async Task RescheduleAsync(Guid id, DateTime scheduledAt)
        {
            var broadcast = await _context.BroadcastNotifications.FindAsync(id);
            if (broadcast == null)
                throw new NotFoundException($"Broadcast notification with ID {id} not found.");

            broadcast.ScheduledAt = scheduledAt;
            broadcast.Status = BroadcastStatus.Scheduled;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Broadcast notification '{Title}' rescheduled to {ScheduledAt}", broadcast.Title, scheduledAt);
        }

        public async Task MarkAsReadAsync(Guid id, string userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (notification == null)
                throw new NotFoundException($"Notification with ID {id} not found.");

            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(string userId)
        {
            await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        }

        public async Task<int> GetUnreadCountAsync(string userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }

        public async Task CreateSystemNotificationAsync(string userId, string title, string content, NotificationType type, string? relatedEntityId, string? relatedEntityType)
        {
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = title,
                Content = content,
                Type = type,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                RelatedEntityId = relatedEntityId,
                RelatedEntityType = relatedEntityType
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            _logger.LogInformation("System notification '{Title}' created for user {UserId}", title, userId);
        }

        public async Task<PagedResult<AdminNotificationDto>> GetAllNotificationsAsync(int page, int pageSize)
        {
            var totalCount = await _context.BroadcastNotifications.CountAsync();

            var items = await _context.BroadcastNotifications
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var dtos = items.Select(n => new AdminNotificationDto(
                n.Id,
                n.Title,
                n.Content,
                n.ImageUrl,
                n.Type.ToString(),
                n.TargetGroup,
                n.RecipientCount,
                n.Status.ToString(),
                n.ScheduledAt,
                n.SentAt,
                n.CreatedAt
            )).ToList();

            return new PagedResult<AdminNotificationDto>(dtos, page, pageSize, totalCount);
        }

        private async Task<List<string>> GetUserIdsByGroupAsync(string targetGroup)
        {
            var normalizedGroup = targetGroup.ToLower();

            if (normalizedGroup == "all")
            {
                return await _context.Users
                    .Where(u => u.IsActive)
                    .Select(u => u.Id)
                    .ToListAsync();
            }

            // Map target group names to role names
            string roleName;
            switch (normalizedGroup)
            {
                case "students":
                    roleName = "Student";
                    break;
                case "instructors":
                    roleName = "Instructor";
                    break;
                default:
                    roleName = targetGroup;
                    break;
            }

            var roleId = await _context.Roles
                .Where(r => r.Name == roleName)
                .Select(r => r.Id)
                .FirstOrDefaultAsync();

            if (roleId != null)
            {
                return await _context.UserRoles
                    .Where(ur => ur.RoleId == roleId)
                    .Select(ur => ur.UserId)
                    .ToListAsync();
            }

            return new List<string>();
        }
    }
}
