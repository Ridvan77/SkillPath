namespace SkillPath.Services.DTOs.Report
{
    public record InstructorReportDto(
        string InstructorId,
        string InstructorName,
        int CoursesCount,
        int TotalStudents,
        decimal TotalRevenue,
        double AverageRating
    );
}
