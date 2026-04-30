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

    [HttpPost("create-intent")]
    public async Task<ActionResult<PaymentIntentResponse>> CreatePaymentIntent([FromBody] PaymentIntentRequest request)
    {
        var result = await _paymentService.CreatePaymentIntentAsync(request.ReservationId);
        _logger.LogInformation("Payment intent created for reservation {ReservationId}.", request.ReservationId);
        return Ok(result);
    }

    [HttpPost("confirm")]
    public async Task<ActionResult<PaymentDto>> ConfirmPayment([FromBody] ConfirmPaymentRequest request)
    {
        var result = await _paymentService.ConfirmPaymentAsync(request.PaymentIntentId);
        _logger.LogInformation("Payment confirmed for intent {PaymentIntentId}.", request.PaymentIntentId);
        return Ok(result);
    }
}

public class ConfirmPaymentRequest
{
    public string PaymentIntentId { get; set; } = string.Empty;
}
