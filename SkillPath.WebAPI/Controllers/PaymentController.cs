using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Payment;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(IPaymentService paymentService, ILogger<PaymentController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    [HttpPost("create-checkout")]
    public async Task<ActionResult<PaymentIntentResponse>> CreateCheckout([FromBody] CreateCheckoutRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _paymentService.CreatePaymentIntentAsync(request.ReservationId, userId, request);
        _logger.LogInformation("Payment checkout created for reservation {ReservationId}.", request.ReservationId);
        return Ok(result);
    }

    [HttpPost("create-intent")]
    public async Task<ActionResult<PaymentIntentResponse>> CreatePaymentIntent([FromBody] PaymentIntentRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _paymentService.CreatePaymentIntentAsync(request.ReservationId, userId);
        _logger.LogInformation("Payment intent created for reservation {ReservationId}.", request.ReservationId);
        return Ok(result);
    }

    [HttpPost("confirm")]
    public async Task<ActionResult<PaymentDto>> ConfirmPayment([FromBody] ConfirmPaymentRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _paymentService.ConfirmPaymentAsync(request.PaymentIntentId);
        _logger.LogInformation("Payment confirmed for intent {PaymentIntentId} by user {UserId}.", request.PaymentIntentId, userId);
        return Ok(result);
    }
}

public class ConfirmPaymentRequest
{
    public string PaymentIntentId { get; set; } = string.Empty;
}
