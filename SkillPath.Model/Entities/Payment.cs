using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public class Payment
    {
        public Guid Id { get; set; }
        public Guid ReservationId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public string? PaymentMethod { get; set; }
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string? StripePaymentIntentId { get; set; }
        public string? StripeChargeId { get; set; }
        public DateTime TransactionDate { get; set; } = DateTime.UtcNow;
        public DateTime? ProcessedDate { get; set; }
        public decimal? RefundAmount { get; set; }
        public DateTime? RefundDate { get; set; }
        public string? RefundReason { get; set; }

        // Navigation properties
        public virtual Reservation Reservation { get; set; } = null!;
    }
}
