using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs.Payment;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;
using Stripe;

namespace SkillPath.Services.Services
{
    public class StripePaymentService : IPaymentService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<StripePaymentService> _logger;
        private readonly IConfiguration _configuration;

        public StripePaymentService(
            ApplicationDbContext context,
            ILogger<StripePaymentService> logger,
            IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _configuration = configuration;

            StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
        }

        public async Task<PaymentIntentResponse> CreatePaymentIntentAsync(Guid reservationId)
        {
            var reservation = await _context.Reservations
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
                throw new NotFoundException($"Reservation with ID {reservationId} not found.");

            if (reservation.Status != ReservationStatus.Pending)
                throw new BusinessException("Payment can only be created for pending reservations.");

            var amountInSmallestUnit = (long)(reservation.TotalAmount * 100);

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInSmallestUnit,
                Currency = "bam",
                Metadata = new Dictionary<string, string>
                {
                    { "reservationId", reservationId.ToString() },
                    { "reservationCode", reservation.ReservationCode }
                }
            };

            var service = new PaymentIntentService();
            var paymentIntent = await service.CreateAsync(options);

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                ReservationId = reservationId,
                Amount = reservation.TotalAmount,
                Currency = "BAM",
                Status = PaymentStatus.Pending,
                StripePaymentIntentId = paymentIntent.Id,
                TransactionDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            _logger.LogInformation("PaymentIntent {PaymentIntentId} created for reservation {ReservationId}, amount {Amount} BAM",
                paymentIntent.Id, reservationId, reservation.TotalAmount);

            return new PaymentIntentResponse(
                paymentIntent.ClientSecret,
                paymentIntent.Id,
                reservation.TotalAmount,
                "BAM"
            );
        }

        public async Task<PaymentDto> ConfirmPaymentAsync(string paymentIntentId)
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntentId);

            if (payment == null)
                throw new NotFoundException($"Payment with PaymentIntentId '{paymentIntentId}' not found.");

            var service = new PaymentIntentService();
            var paymentIntent = await service.GetAsync(paymentIntentId);

            if (paymentIntent.Status == "succeeded")
            {
                payment.Status = PaymentStatus.Succeeded;
                payment.ProcessedDate = DateTime.UtcNow;
                payment.PaymentMethod = paymentIntent.PaymentMethodTypes?.FirstOrDefault() ?? "card";

                if (paymentIntent.LatestCharge != null)
                {
                    payment.StripeChargeId = paymentIntent.LatestChargeId;
                }
            }
            else
            {
                payment.Status = PaymentStatus.Failed;
                payment.ProcessedDate = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Payment {PaymentId} confirmed with status {Status} for PaymentIntent {PaymentIntentId}",
                payment.Id, payment.Status, paymentIntentId);

            return new PaymentDto(
                payment.Id,
                payment.ReservationId,
                payment.Amount,
                payment.Currency,
                payment.PaymentMethod ?? string.Empty,
                payment.Status.ToString(),
                payment.StripePaymentIntentId,
                payment.TransactionDate,
                payment.ProcessedDate
            );
        }

        public async Task<PaymentDto> RefundPaymentAsync(Guid reservationId, string reason)
        {
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId && p.Status == PaymentStatus.Succeeded);

            if (payment == null)
                throw new NotFoundException($"No successful payment found for reservation {reservationId}.");

            var refundOptions = new RefundCreateOptions
            {
                PaymentIntent = payment.StripePaymentIntentId,
                Reason = "requested_by_customer"
            };

            var refundService = new RefundService();
            var refund = await refundService.CreateAsync(refundOptions);

            payment.Status = PaymentStatus.Refunded;
            payment.RefundAmount = payment.Amount;
            payment.RefundDate = DateTime.UtcNow;
            payment.RefundReason = reason;

            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation != null)
            {
                reservation.RefundAmount = payment.Amount;
                reservation.RefundedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            _logger.LogInformation("Refund {RefundId} processed for payment {PaymentId}, reservation {ReservationId}",
                refund.Id, payment.Id, reservationId);

            return new PaymentDto(
                payment.Id,
                payment.ReservationId,
                payment.Amount,
                payment.Currency,
                payment.PaymentMethod ?? string.Empty,
                payment.Status.ToString(),
                payment.StripePaymentIntentId,
                payment.TransactionDate,
                payment.ProcessedDate
            );
        }
    }
}
