using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public enum BroadcastStatus
    {
        Draft = 0,
        Scheduled = 1,
        Sent = 2
    }

    public class BroadcastNotification
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public NotificationType Type { get; set; }
        public string TargetGroup { get; set; } = "all";
        public BroadcastStatus Status { get; set; } = BroadcastStatus.Draft;
        public DateTime? ScheduledAt { get; set; }
        public DateTime? SentAt { get; set; }
        public int RecipientCount { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
