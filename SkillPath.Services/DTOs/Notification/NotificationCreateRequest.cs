using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Notification
{
    public class NotificationCreateRequest
    {
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(2000)]
        public string Content { get; set; } = string.Empty;

        public string? ImageUrl { get; set; }

        [Required]
        public int Type { get; set; }

        public string? UserId { get; set; }

        public string? TargetGroup { get; set; }

        /// <summary>
        /// If set, notification will be scheduled for this time. If null and SaveAsDraft is false, sends immediately.
        /// </summary>
        public DateTime? ScheduledAt { get; set; }

        /// <summary>
        /// If true, saves as draft without sending or scheduling.
        /// </summary>
        public bool SaveAsDraft { get; set; }
    }
}
