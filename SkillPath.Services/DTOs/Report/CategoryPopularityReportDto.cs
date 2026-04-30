namespace SkillPath.Services.DTOs.Report
{
    public record CategoryPopularityReportDto(
        int CategoryId,
        string CategoryName,
        int CoursesCount,
        int EnrollmentCount,
        decimal Revenue,
        double AverageRating
    );
}
