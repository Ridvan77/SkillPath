using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Course;

namespace SkillPath.Services.Interfaces;

public interface ICourseService
{
    Task<PagedResult<CourseDto>> GetAllAsync(CourseSearchRequest request);
    Task<CourseDetailDto> GetByIdAsync(Guid id);
    Task<CourseDto> CreateAsync(CourseCreateRequest request);
    Task<CourseDto> UpdateAsync(Guid id, CourseUpdateRequest request);
    Task DeleteAsync(Guid id);
    Task<List<CourseDto>> GetInstructorCoursesAsync(string instructorId);
}
