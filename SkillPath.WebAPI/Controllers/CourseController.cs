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
        var result = await _courseService.UpdateAsync(id, request);
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
