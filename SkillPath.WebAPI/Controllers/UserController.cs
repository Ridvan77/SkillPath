using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.User;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UserController> _logger;

    public UserController(IUserService userService, ILogger<UserController> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? role = null)
    {
        var result = await _userService.GetAllAsync(page, pageSize, search, role);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetById(string id)
    {
        var result = await _userService.GetByIdAsync(id);
        return Ok(result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<UserDto>> Update(string id, [FromBody] UserUpdateRequest request)
    {
        var result = await _userService.UpdateAsync(id, request);
        _logger.LogInformation("User {UserId} updated by admin.", id);
        return Ok(result);
    }

    [HttpPut("{id}/toggle-active")]
    public async Task<ActionResult> ToggleActive(string id)
    {
        await _userService.ToggleActiveAsync(id);
        _logger.LogInformation("User {UserId} active status toggled by admin.", id);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(string id)
    {
        await _userService.DeleteAsync(id);
        _logger.LogInformation("User {UserId} permanently deleted by admin.", id);
        return NoContent();
    }
}
