using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FavoriteController : ControllerBase
{
    private readonly IFavoriteService _favoriteService;
    private readonly ILogger<FavoriteController> _logger;

    public FavoriteController(IFavoriteService favoriteService, ILogger<FavoriteController> logger)
    {
        _favoriteService = favoriteService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var result = await _favoriteService.GetUserFavoritesAsync(userId, page, pageSize);
        return Ok(result);
    }

    [HttpPost("{courseId:guid}")]
    public async Task<ActionResult> ToggleFavorite(Guid courseId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var isFavorite = await _favoriteService.ToggleFavoriteAsync(userId, courseId);
        _logger.LogInformation("User {UserId} toggled favorite for course {CourseId}. IsFavorite: {IsFavorite}", userId, courseId, isFavorite);
        return Ok(new { isFavorite });
    }

    [HttpGet("{courseId:guid}/status")]
    public async Task<ActionResult> GetStatus(Guid courseId)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var isFavorite = await _favoriteService.IsFavoriteAsync(userId, courseId);
        return Ok(new { isFavorite });
    }
}
