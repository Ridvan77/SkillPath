using SkillPath.Services.DTOs.CourseSchedule;

namespace SkillPath.Services.Interfaces;

public interface ICourseScheduleService
{
    Task<List<CourseScheduleDto>> GetByCourseIdAsync(Guid courseId);
    Task<CourseScheduleDto> CreateAsync(CourseScheduleCreateRequest request);
    Task<CourseScheduleDto> UpdateAsync(Guid id, CourseScheduleUpdateRequest request);
    Task DeleteAsync(Guid id);
}
