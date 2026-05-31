using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Course;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CourseController : ControllerBase
{
    private readonly ICourseService _courseService;
    private readonly ILogger<CourseController> _logger;

    public CourseController(ICourseService courseService, ILogger<CourseController> logger)
    {
        _courseService = courseService;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult> GetAll([FromQuery] CourseSearchRequest request)
    {
        var result = await _courseService.GetAllAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<CourseDetailDto>> GetById(Guid id)
    {
        var result = await _courseService.GetByIdAsync(id);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CourseDto>> Create([FromBody] CourseCreateRequest request)
    {
        var result = await _courseService.CreateAsync(request);
        _logger.LogInformation("Course {CourseId} created.", result.Id);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Instructor")]
    public async Task<ActionResult<CourseDto>> Update(Guid id, [FromBody] CourseUpdateRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId == null) return Unauthorized();

        var isAdmin = User.IsInRole("Admin");

        var result = await _courseService.UpdateAsync(id, request, userId, isAdmin);
        _logger.LogInformation("Course {CourseId} updated.", id);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(Guid id)
    {
        await _courseService.DeleteAsync(id);
        _logger.LogInformation("Course {CourseId} soft-deleted.", id);
        return NoContent();
    }

    [HttpPost("upload-image")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> UploadImage(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file provided.");

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
            return BadRequest("Invalid file type. Allowed: jpg, jpeg, png, webp.");

        if (file.Length > 5 * 1024 * 1024)
            return BadRequest("File size must be less than 5MB.");

        // Item 20: MIME type validation
        var allowedMimeTypes = new[] { "image/jpeg", "image/png", "image/webp" };
        if (!allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
            return BadRequest("Nevazeci MIME tip fajla. Dozvoljeni: image/jpeg, image/png, image/webp.");

        // Item 20: Magic bytes validation
        using var headerStream = file.OpenReadStream();
        var header = new byte[4];
        await headerStream.ReadAsync(header, 0, 4);
        headerStream.Position = 0;

        bool isValidImage = false;
        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
            isValidImage = true;
        // PNG: 89 50 4E 47
        else if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47)
            isValidImage = true;
        // WEBP: 52 49 46 46 (RIFF)
        else if (header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46)
            isValidImage = true;

        if (!isValidImage)
            return BadRequest("Fajl ne izgleda kao validna slika. Sadrzaj ne odgovara dozvoljenom formatu.");

        var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "courses");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(uploadsDir, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var imageUrl = $"/uploads/courses/{fileName}";
        return Ok(new { imageUrl });
    }

    [HttpGet("instructor/{instructorId}")]
    [Authorize(Roles = "Admin,Instructor")]
    public async Task<ActionResult<List<CourseDto>>> GetInstructorCourses(string instructorId)
    {
        var result = await _courseService.GetInstructorCoursesAsync(instructorId);
        return Ok(result);
    }
}
