namespace SkillPath.Services.DTOs.CourseSchedule
{
    public record CourseScheduleDto(
        Guid Id,
        Guid CourseId,
        string DayOfWeek,
        string StartTime,
        string EndTime,
        DateTime StartDate,
        DateTime EndDate,
        int MaxCapacity,
        int CurrentEnrollment,
        bool IsActive
    );
}
