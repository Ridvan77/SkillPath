using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public class ReservationStatusHistory
    {
        public Guid Id { get; set; }
        public Guid ReservationId { get; set; }
        public ReservationStatus OldStatus { get; set; }
        public ReservationStatus NewStatus { get; set; }
        public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
        public string? ChangedById { get; set; }
        public string? Note { get; set; }

        // Navigation properties
        public virtual Reservation Reservation { get; set; } = null!;
        public virtual ApplicationUser? ChangedBy { get; set; }
    }
}
