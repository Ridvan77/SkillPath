namespace SkillPath.Services.DTOs.Payment
{
    public record PaymentIntentResponse(
        string ClientSecret,
        string PaymentIntentId,
        decimal Amount,
        string Currency,
        string? EphemeralKeySecret = null,
        string? CustomerId = null
    );
}
