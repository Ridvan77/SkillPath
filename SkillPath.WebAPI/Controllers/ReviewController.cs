using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Review;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReviewController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly ILogger<ReviewController> _logger;

    public ReviewController(IReviewService reviewService, ILogger<ReviewController> logger)
    {
        _reviewService = reviewService;
        _logger = logger;
    }

    [HttpGet("course/{courseId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<CourseReviewsDto>> GetCourseReviews(
        Guid courseId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool includeHidden = false)
    {
        string? currentUserId = User.Identity?.IsAuthenticated == true
            ? User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            : null;

        var result = await _reviewService.GetCourseReviewsAsync(courseId, currentUserId, page, pageSize, includeHidden);
        return Ok(result);
    }

    [HttpGet("course/{courseId:guid}/can-review")]
    [Authorize]
    public async Task<ActionResult> CanReview(Guid courseId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var canReview = await _reviewService.CanUserReviewAsync(userId, courseId);
        return Ok(new { canReview });
    }

    [HttpPost("course/{courseId:guid}")]
    [Authorize]
    public async Task<ActionResult<ReviewDto>> Create(Guid courseId, [FromBody] CreateReviewRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _reviewService.CreateAsync(userId, courseId, request);
        _logger.LogInformation("Review {ReviewId} created by user {UserId} for course {CourseId}.", result.Id, userId, courseId);
        return Created(string.Empty, result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize]
    public async Task<ActionResult> Delete(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var isAdmin = User.IsInRole("Admin");
        await _reviewService.DeleteAsync(id, userId, isAdmin);
        _logger.LogInformation("Review {ReviewId} deleted by user {UserId}.", id, userId);
        return NoContent();
    }

    [HttpPost("{id:guid}/helpful")]
    [Authorize]
    public async Task<ActionResult> ToggleHelpful(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        await _reviewService.VoteHelpfulAsync(id, userId);
        _logger.LogInformation("User {UserId} toggled helpful vote on review {ReviewId}.", userId, id);
        return Ok();
    }

    [HttpPut("{id:guid}/visibility")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ReviewDto>> ToggleVisibility(Guid id)
    {
        var result = await _reviewService.ToggleVisibilityAsync(id);
        _logger.LogInformation("Review {ReviewId} visibility toggled.", id);
        return Ok(result);
    }
}
