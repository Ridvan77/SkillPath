using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public class Reservation
    {
        public Guid Id { get; set; }
        public string ReservationCode { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public Guid CourseScheduleId { get; set; }
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CancelledAt { get; set; }
        public string? CancellationReason { get; set; }
        public decimal? RefundAmount { get; set; }
        public DateTime? RefundedAt { get; set; }
        public bool IsDeleted { get; set; }

        // Navigation properties
        public virtual ApplicationUser User { get; set; } = null!;
        public virtual CourseSchedule CourseSchedule { get; set; } = null!;
        public virtual Payment? Payment { get; set; }
        public virtual ICollection<ReservationStatusHistory> StatusHistory { get; set; } = new List<ReservationStatusHistory>();
    }
}
