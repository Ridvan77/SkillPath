using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Recommender;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RecommenderController : ControllerBase
{
    private readonly IRecommenderService _recommenderService;
    private readonly ILogger<RecommenderController> _logger;

    public RecommenderController(IRecommenderService recommenderService, ILogger<RecommenderController> logger)
    {
        _recommenderService = recommenderService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<List<RecommendationDto>>> GetRecommendations([FromQuery] int count = 10)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _recommenderService.GetRecommendationsAsync(userId, count);
        return Ok(result);
    }

    [HttpPost("track-view")]
    public async Task<ActionResult> TrackView([FromBody] TrackViewRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        await _recommenderService.TrackCourseViewAsync(userId, request.CourseId);
        _logger.LogInformation("User {UserId} viewed course {CourseId}.", userId, request.CourseId);
        return Ok();
    }
}

public class TrackViewRequest
{
    public Guid CourseId { get; set; }
}
