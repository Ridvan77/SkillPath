namespace SkillPath.Services.DTOs.Report
{
    public record InstructorReportResponse(
        List<InstructorReportDto> Instructors,
        int TotalInstructors,
        int TotalStudents,
        decimal TotalRevenue,
        DateTime? FromDate,
        DateTime? ToDate
    );
}
