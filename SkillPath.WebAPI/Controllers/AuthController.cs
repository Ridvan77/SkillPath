using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Model;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Auth;
using SkillPath.Services.Helpers;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthController> _logger;
    private readonly IRabbitMQPublisherService _rabbitMQPublisherService;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        IJwtService jwtService,
        ILogger<AuthController> logger,
        IRabbitMQPublisherService rabbitMQPublisherService)
    {
        _userManager = userManager;
        _jwtService = jwtService;
        _logger = logger;
        _rabbitMQPublisherService = rabbitMQPublisherService;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        var existingUser = await _userManager.FindByEmailAsync(request.Email);
        if (existingUser != null)
            return BadRequest(new { message = "A user with this email already exists." });

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            PhoneNumber = request.PhoneNumber,
            CityId = request.CityId,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return BadRequest(new { message = "Registration failed.", errors = result.Errors.Select(e => e.Description) });

        await _userManager.AddToRoleAsync(user, "Student");
        var roles = await _userManager.GetRolesAsync(user);

        var accessToken = _jwtService.GenerateAccessToken(user, roles);
        var refreshToken = _jwtService.GenerateRefreshToken();

        _logger.LogInformation("User {Email} registered successfully.", user.Email);

        try
        {
            var emailBody = EmailTemplateHelper.WelcomeEmail(user.FirstName, user.LastName);
            await _rabbitMQPublisherService.PublishEmailAsync(new EmailMessage
            {
                ToEmail = user.Email!,
                Subject = "Dobrodosli na SkillPath!",
                Body = emailBody
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send welcome email to {Email}.", user.Email);
        }

        return Created(string.Empty, new AuthResponse(
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email!,
            roles.ToList(),
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(1)
        ));
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user == null || !user.IsActive)
            return Unauthorized(new { message = "Invalid email or password." });

        var isValidPassword = await _userManager.CheckPasswordAsync(user, request.Password);
        if (!isValidPassword)
            return Unauthorized(new { message = "Invalid email or password." });

        var roles = await _userManager.GetRolesAsync(user);
        var accessToken = _jwtService.GenerateAccessToken(user, roles);
        var refreshToken = _jwtService.GenerateRefreshToken();

        user.LastLoginAt = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        _logger.LogInformation("User {Email} logged in successfully.", user.Email);

        return Ok(new AuthResponse(
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email!,
            roles.ToList(),
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(1)
        ));
    }

    [HttpGet("profile")]
    [Authorize]
    public async Task<ActionResult> GetProfile()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
            return NotFound();

        var roles = await _userManager.GetRolesAsync(user);

        return Ok(new
        {
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.ProfileImageUrl,
            user.CityId,
            user.CreatedAt,
            user.LastLoginAt,
            Roles = roles
        });
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<ActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
            return NotFound();

        user.FirstName = request.FirstName;
        user.LastName = request.LastName;
        user.PhoneNumber = request.PhoneNumber;
        user.ProfileImageUrl = request.ProfileImageUrl;
        user.CityId = request.CityId;

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { message = "Failed to update profile.", errors = result.Errors.Select(e => e.Description) });

        _logger.LogInformation("User {UserId} updated their profile.", userId);

        return Ok(new
        {
            user.Id,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.ProfileImageUrl,
            user.CityId
        });
    }

    [HttpPut("change-password")]
    [Authorize]
    public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
            return NotFound();

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!result.Succeeded)
            return BadRequest(new { message = "Failed to change password.", errors = result.Errors.Select(e => e.Description) });

        _logger.LogInformation("User {UserId} changed their password.", userId);

        // Send password change notification email
        try
        {
            await _rabbitMQPublisherService.PublishEmailAsync(new SkillPath.Services.DTOs.EmailMessage
            {
                ToEmail = user.Email!,
                Subject = "SkillPath - Lozinka promijenjena",
                Body = SkillPath.Services.Helpers.EmailTemplateHelper.PasswordChangedEmail(user.FirstName, user.LastName)
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send password change email for user {UserId}", userId);
        }

        return NoContent();
    }
}

public class UpdateProfileRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public int? CityId { get; set; }
}
