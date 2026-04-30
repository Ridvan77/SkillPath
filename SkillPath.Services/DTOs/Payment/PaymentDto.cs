namespace SkillPath.Services.DTOs.Payment
{
    public record PaymentDto(
        Guid Id,
        Guid ReservationId,
        decimal Amount,
        string Currency,
        string PaymentMethod,
        string Status,
        string? StripePaymentIntentId,
        DateTime TransactionDate,
        DateTime? ProcessedDate
    );
}
