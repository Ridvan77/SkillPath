using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public class Notification
    {
        public Guid Id { get; set; }
        public string? UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public NotificationType Type { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string? RelatedEntityId { get; set; }
        public string? RelatedEntityType { get; set; }

        // Navigation properties
        public virtual ApplicationUser? User { get; set; }
    }
}
