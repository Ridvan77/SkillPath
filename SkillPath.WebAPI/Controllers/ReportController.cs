using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Report;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class ReportController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportController> _logger;

    public ReportController(IReportService reportService, ILogger<ReportController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    [HttpGet("instructor")]
    public async Task<ActionResult<InstructorReportResponse>> GetInstructorReport(
        [FromQuery] string? instructorIds = null,
        [FromQuery] DateTime? from = null,
        [FromQuery] DateTime? to = null)
    {
        List<string>? idList = null;
        if (!string.IsNullOrWhiteSpace(instructorIds))
            idList = instructorIds.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList();

        var result = await _reportService.GetInstructorReportAsync(idList, from, to);
        return Ok(result);
    }

    [HttpGet("category-popularity")]
    public async Task<ActionResult<List<CategoryPopularityReportDto>>> GetCategoryPopularity(
        [FromQuery] DateTime? from = null,
        [FromQuery] DateTime? to = null,
        [FromQuery] string? categoryIds = null)
    {
        List<int>? idList = null;
        if (!string.IsNullOrWhiteSpace(categoryIds))
            idList = categoryIds.Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(int.Parse).ToList();

        var result = await _reportService.GetCategoryPopularityReportAsync(from, to, idList);
        return Ok(result);
    }
}
