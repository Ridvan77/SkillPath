using SkillPath.Services.DTOs.Payment;

namespace SkillPath.Services.Interfaces;

public interface IPaymentService
{
    Task<PaymentIntentResponse> CreatePaymentIntentAsync(Guid reservationId);
    Task<PaymentDto> ConfirmPaymentAsync(string paymentIntentId);
    Task<PaymentDto> RefundPaymentAsync(Guid reservationId, string reason);
}
