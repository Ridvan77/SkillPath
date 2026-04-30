using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.CourseSchedule;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/course-schedules")]
public class CourseScheduleController : ControllerBase
{
    private readonly ICourseScheduleService _courseScheduleService;
    private readonly ILogger<CourseScheduleController> _logger;

    public CourseScheduleController(ICourseScheduleService courseScheduleService, ILogger<CourseScheduleController> logger)
    {
        _courseScheduleService = courseScheduleService;
        _logger = logger;
    }

    [HttpGet("course/{courseId:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<List<CourseScheduleDto>>> GetByCourseId(Guid courseId)
    {
        var result = await _courseScheduleService.GetByCourseIdAsync(courseId);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CourseScheduleDto>> Create([FromBody] CourseScheduleCreateRequest request)
    {
        var result = await _courseScheduleService.CreateAsync(request);
        _logger.LogInformation("CourseSchedule {ScheduleId} created.", result.Id);
        return Created(string.Empty, result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CourseScheduleDto>> Update(Guid id, [FromBody] CourseScheduleUpdateRequest request)
    {
        var result = await _courseScheduleService.UpdateAsync(id, request);
        _logger.LogInformation("CourseSchedule {ScheduleId} updated.", id);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(Guid id)
    {
        await _courseScheduleService.DeleteAsync(id);
        _logger.LogInformation("CourseSchedule {ScheduleId} deleted.", id);
        return NoContent();
    }
}
