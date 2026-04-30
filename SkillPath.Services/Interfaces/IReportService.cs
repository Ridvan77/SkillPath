using SkillPath.Services.DTOs.Report;

namespace SkillPath.Services.Interfaces;

public interface IReportService
{
    Task<InstructorReportResponse> GetInstructorReportAsync(List<string>? instructorIds, DateTime? from, DateTime? to);
    Task<List<CategoryPopularityReportDto>> GetCategoryPopularityReportAsync(DateTime? from, DateTime? to, List<int>? categoryIds = null);
}
