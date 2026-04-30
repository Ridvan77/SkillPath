using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs.CourseSchedule;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class CourseScheduleService : ICourseScheduleService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CourseScheduleService> _logger;

        public CourseScheduleService(ApplicationDbContext context, ILogger<CourseScheduleService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<CourseScheduleDto>> GetByCourseIdAsync(Guid courseId)
        {
            var courseExists = await _context.Courses.AnyAsync(c => c.Id == courseId);
            if (!courseExists)
                throw new NotFoundException($"Course with ID {courseId} not found.");

            return await _context.CourseSchedules
                .Where(cs => cs.CourseId == courseId && cs.IsActive)
                .Select(cs => new CourseScheduleDto(
                    cs.Id,
                    cs.CourseId,
                    cs.DayOfWeek.ToString(),
                    cs.StartTime.ToString(@"hh\:mm"),
                    cs.EndTime.ToString(@"hh\:mm"),
                    cs.StartDate,
                    cs.EndDate,
                    cs.MaxCapacity,
                    cs.CurrentEnrollment,
                    cs.IsActive
                ))
                .ToListAsync();
        }

        public async Task<CourseScheduleDto> CreateAsync(CourseScheduleCreateRequest request)
        {
            var courseExists = await _context.Courses.AnyAsync(c => c.Id == request.CourseId);
            if (!courseExists)
                throw new NotFoundException($"Course with ID {request.CourseId} not found.");

            var schedule = new CourseSchedule
            {
                Id = Guid.NewGuid(),
                CourseId = request.CourseId,
                DayOfWeek = (DayOfWeek)request.DayOfWeek,
                StartTime = TimeSpan.Parse(request.StartTime),
                EndTime = TimeSpan.Parse(request.EndTime),
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                MaxCapacity = request.MaxCapacity,
                CurrentEnrollment = 0,
                IsActive = true
            };

            _context.CourseSchedules.Add(schedule);
            await _context.SaveChangesAsync();

            _logger.LogInformation("CourseSchedule created with ID {Id} for Course {CourseId}", schedule.Id, schedule.CourseId);

            return new CourseScheduleDto(
                schedule.Id,
                schedule.CourseId,
                schedule.DayOfWeek.ToString(),
                schedule.StartTime.ToString(@"hh\:mm"),
                schedule.EndTime.ToString(@"hh\:mm"),
                schedule.StartDate,
                schedule.EndDate,
                schedule.MaxCapacity,
                schedule.CurrentEnrollment,
                schedule.IsActive
            );
        }

        public async Task<CourseScheduleDto> UpdateAsync(Guid id, CourseScheduleUpdateRequest request)
        {
            var schedule = await _context.CourseSchedules.FindAsync(id);
            if (schedule == null)
                throw new NotFoundException($"CourseSchedule with ID {id} not found.");

            if (request.CourseId.HasValue) schedule.CourseId = request.CourseId.Value;
            if (request.DayOfWeek.HasValue) schedule.DayOfWeek = (DayOfWeek)request.DayOfWeek.Value;
            if (request.StartTime != null) schedule.StartTime = TimeSpan.Parse(request.StartTime);
            if (request.EndTime != null) schedule.EndTime = TimeSpan.Parse(request.EndTime);
            if (request.StartDate.HasValue) schedule.StartDate = request.StartDate.Value;
            if (request.EndDate.HasValue) schedule.EndDate = request.EndDate.Value;
            if (request.MaxCapacity.HasValue) schedule.MaxCapacity = request.MaxCapacity.Value;

            await _context.SaveChangesAsync();

            _logger.LogInformation("CourseSchedule (ID {Id}) updated", schedule.Id);

            return new CourseScheduleDto(
                schedule.Id,
                schedule.CourseId,
                schedule.DayOfWeek.ToString(),
                schedule.StartTime.ToString(@"hh\:mm"),
                schedule.EndTime.ToString(@"hh\:mm"),
                schedule.StartDate,
                schedule.EndDate,
                schedule.MaxCapacity,
                schedule.CurrentEnrollment,
                schedule.IsActive
            );
        }

        public async Task DeleteAsync(Guid id)
        {
            var schedule = await _context.CourseSchedules.FindAsync(id);
            if (schedule == null)
                throw new NotFoundException($"CourseSchedule with ID {id} not found.");

            schedule.IsActive = false;
            await _context.SaveChangesAsync();

            _logger.LogInformation("CourseSchedule (ID {Id}) deactivated", schedule.Id);
        }
    }
}
