using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs.Reservation;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReservationController : ControllerBase
{
    private readonly IReservationService _reservationService;
    private readonly ILogger<ReservationController> _logger;

    public ReservationController(IReservationService reservationService, ILogger<ReservationController> logger)
    {
        _reservationService = reservationService;
        _logger = logger;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] ReservationStatus? status = null)
    {
        var result = await _reservationService.GetAllAsync(page, pageSize, search, status);
        return Ok(result);
    }

    [HttpGet("my")]
    public async Task<ActionResult> GetMyReservations(
        [FromQuery] ReservationStatus? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _reservationService.GetUserReservationsAsync(userId, status, page, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ReservationDto>> GetById(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _reservationService.GetByIdAsync(id);

        var isAdmin = User.IsInRole("Admin");
        if (!isAdmin && result.UserId != userId)
            return Forbid();

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<ReservationDto>> Create([FromBody] ReservationCreateRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _reservationService.CreateAsync(userId, request);
        _logger.LogInformation("Reservation {ReservationId} created by user {UserId}.", result.Id, userId);
        return Created(string.Empty, result);
    }

    [HttpPost("{id:guid}/confirm")]
    public async Task<ActionResult<ReservationDto>> Confirm(Guid id, [FromBody] ConfirmReservationRequest request)
    {
        var result = await _reservationService.ConfirmAsync(id, request.StripePaymentIntentId);
        _logger.LogInformation("Reservation {ReservationId} confirmed.", id);
        return Ok(result);
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<ActionResult<ReservationDto>> Cancel(Guid id, [FromBody] ReservationCancelRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _reservationService.CancelAsync(id, userId, request.Reason);
        _logger.LogInformation("Reservation {ReservationId} cancelled by user {UserId}.", id, userId);
        return Ok(result);
    }
}

public class ConfirmReservationRequest
{
    public string StripePaymentIntentId { get; set; } = string.Empty;
}
