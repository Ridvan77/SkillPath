using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Notification;
using SkillPath.Services.Interfaces;
using SkillPath.Services.Services;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly IFirebaseService _firebaseService;
    private readonly ILogger<NotificationController> _logger;

    public NotificationController(INotificationService notificationService, IFirebaseService firebaseService, ILogger<NotificationController> logger)
    {
        _notificationService = notificationService;
        _firebaseService = firebaseService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult> GetAll(
        [FromQuery] bool? isRead = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _notificationService.GetUserNotificationsAsync(userId, isRead, page, pageSize);
        return Ok(result);
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetAllAdmin(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _notificationService.GetAllNotificationsAsync(page, pageSize);
        return Ok(result);
    }

    [HttpPut("admin/{id:guid}/schedule")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Reschedule(Guid id, [FromBody] RescheduleRequest request)
    {
        await _notificationService.RescheduleAsync(id, request.ScheduledAt);
        return Ok();
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult> GetUnreadCount()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var count = await _notificationService.GetUnreadCountAsync(userId);
        return Ok(new { unreadCount = count });
    }

    [HttpPut("{id:guid}/read")]
    public async Task<ActionResult> MarkAsRead(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        await _notificationService.MarkAsReadAsync(id, userId);
        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<ActionResult> MarkAllAsRead()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        await _notificationService.MarkAllAsReadAsync(userId);
        return NoContent();
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<NotificationDto>> Create([FromBody] NotificationCreateRequest request)
    {
        var result = await _notificationService.CreateAsync(request);
        _logger.LogInformation("Notification {NotificationId} created.", result.Id);

        // Send FCM push only for immediate notifications (not scheduled)
        if (!request.ScheduledAt.HasValue)
        {
            try
            {
                if (request.TargetGroup != null)
                    await _firebaseService.SendToGroupAsync(request.TargetGroup, request.Title, request.Content);
                else if (request.UserId != null)
                    await _firebaseService.SendToUserAsync(request.UserId, request.Title, request.Content);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send FCM notification");
            }
        }

        return Created(string.Empty, result);
    }

    [HttpPost("fcm-token")]
    [Authorize]
    public async Task<ActionResult> RegisterFcmToken([FromBody] FcmTokenRequest request)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        await _firebaseService.RegisterTokenAsync(userId, request.Token, request.Platform);
        return Ok();
    }
}

public record FcmTokenRequest(string Token, string Platform);
public record RescheduleRequest(DateTime ScheduledAt);
