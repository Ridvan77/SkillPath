using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Course;
using SkillPath.Services.DTOs.CourseSchedule;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class CourseService : ICourseService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CourseService> _logger;

        public CourseService(ApplicationDbContext context, ILogger<CourseService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<PagedResult<CourseDto>> GetAllAsync(CourseSearchRequest request)
        {
            var query = _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .Where(c => c.IsActive)
                .AsQueryable();

            if (request.CategoryId.HasValue)
                query = query.Where(c => c.CategoryId == request.CategoryId.Value);

            if (request.DifficultyLevel.HasValue)
                query = query.Where(c => (int)c.DifficultyLevel == request.DifficultyLevel.Value);

            if (request.MinPrice.HasValue)
                query = query.Where(c => c.Price >= request.MinPrice.Value);

            if (request.MaxPrice.HasValue)
                query = query.Where(c => c.Price <= request.MaxPrice.Value);

            if (!string.IsNullOrWhiteSpace(request.InstructorId))
                query = query.Where(c => c.InstructorId == request.InstructorId);

            if (request.IsFeatured.HasValue)
                query = query.Where(c => c.IsFeatured == request.IsFeatured.Value);

            if (!string.IsNullOrWhiteSpace(request.Search))
            {
                var search = request.Search.ToLower();
                query = query.Where(c =>
                    c.Title.ToLower().Contains(search) ||
                    (c.Instructor.FirstName + " " + c.Instructor.LastName).ToLower().Contains(search));
            }

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(c => c.CreatedAt)
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(c => new CourseDto(
                    c.Id,
                    c.Title,
                    c.ShortDescription,
                    c.Price,
                    c.DurationWeeks,
                    c.DifficultyLevel.ToString(),
                    c.ImageUrl,
                    c.IsActive,
                    c.IsFeatured,
                    c.CategoryId,
                    c.Category.Name,
                    c.InstructorId,
                    c.Instructor.FirstName + " " + c.Instructor.LastName,
                    c.Reviews.Where(r => r.IsVisible).Any()
                        ? c.Reviews.Where(r => r.IsVisible).Average(r => (double)r.Rating)
                        : 0,
                    c.Reviews.Count(r => r.IsVisible),
                    c.CreatedAt
                ))
                .ToListAsync();

            return new PagedResult<CourseDto>(items, request.Page, request.PageSize, totalCount);
        }

        public async Task<CourseDetailDto> GetByIdAsync(Guid id)
        {
            var course = await _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .Include(c => c.Schedules)
                .Where(c => c.Id == id)
                .Select(c => new CourseDetailDto(
                    c.Id,
                    c.Title,
                    c.ShortDescription,
                    c.Price,
                    c.DurationWeeks,
                    c.DifficultyLevel.ToString(),
                    c.ImageUrl,
                    c.IsActive,
                    c.IsFeatured,
                    c.CategoryId,
                    c.Category.Name,
                    c.InstructorId,
                    c.Instructor.FirstName + " " + c.Instructor.LastName,
                    c.Reviews.Where(r => r.IsVisible).Any()
                        ? c.Reviews.Where(r => r.IsVisible).Average(r => (double)r.Rating)
                        : 0,
                    c.Reviews.Count(r => r.IsVisible),
                    c.CreatedAt,
                    c.Description,
                    c.Schedules.Where(s => s.IsActive).Select(s => new CourseScheduleDto(
                        s.Id,
                        s.CourseId,
                        s.DayOfWeek.ToString(),
                        s.StartTime.ToString(@"hh\:mm"),
                        s.EndTime.ToString(@"hh\:mm"),
                        s.StartDate,
                        s.EndDate,
                        s.MaxCapacity,
                        s.CurrentEnrollment,
                        s.IsActive
                    )).ToList()
                ))
                .FirstOrDefaultAsync();

            if (course == null)
                throw new NotFoundException($"Course with ID {id} not found.");

            return course;
        }

        public async Task<CourseDto> CreateAsync(CourseCreateRequest request)
        {
            var course = new Course
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Description = request.Description,
                ShortDescription = request.ShortDescription,
                Price = request.Price,
                DurationWeeks = request.DurationWeeks,
                DifficultyLevel = (DifficultyLevel)request.DifficultyLevel,
                ImageUrl = request.ImageUrl,
                IsFeatured = request.IsFeatured,
                CategoryId = request.CategoryId,
                InstructorId = request.InstructorId,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Courses.Add(course);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Course '{Title}' created with ID {Id}", course.Title, course.Id);

            var category = await _context.Categories.FindAsync(course.CategoryId);
            var instructor = await _context.Users.FindAsync(course.InstructorId);

            return new CourseDto(
                course.Id,
                course.Title,
                course.ShortDescription,
                course.Price,
                course.DurationWeeks,
                course.DifficultyLevel.ToString(),
                course.ImageUrl,
                course.IsActive,
                course.IsFeatured,
                course.CategoryId,
                category?.Name ?? string.Empty,
                course.InstructorId,
                instructor != null ? $"{instructor.FirstName} {instructor.LastName}" : string.Empty,
                0,
                0,
                course.CreatedAt
            );
        }

        public async Task<CourseDto> UpdateAsync(Guid id, CourseUpdateRequest request)
        {
            var course = await _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (course == null)
                throw new NotFoundException($"Course with ID {id} not found.");

            if (request.Title != null) course.Title = request.Title;
            if (request.Description != null) course.Description = request.Description;
            if (request.ShortDescription != null) course.ShortDescription = request.ShortDescription;
            if (request.Price.HasValue) course.Price = request.Price.Value;
            if (request.DurationWeeks.HasValue) course.DurationWeeks = request.DurationWeeks.Value;
            if (request.DifficultyLevel.HasValue) course.DifficultyLevel = (DifficultyLevel)request.DifficultyLevel.Value;
            if (request.ImageUrl != null) course.ImageUrl = request.ImageUrl;
            if (request.IsFeatured.HasValue) course.IsFeatured = request.IsFeatured.Value;
            if (request.CategoryId.HasValue) course.CategoryId = request.CategoryId.Value;
            if (request.InstructorId != null) course.InstructorId = request.InstructorId;

            course.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Course '{Title}' (ID {Id}) updated", course.Title, course.Id);

            await _context.Entry(course).Reference(c => c.Category).LoadAsync();
            await _context.Entry(course).Reference(c => c.Instructor).LoadAsync();

            var reviewStats = await _context.Reviews
                .Where(r => r.CourseId == id && r.IsVisible)
                .GroupBy(r => r.CourseId)
                .Select(g => new { Avg = g.Average(r => (double)r.Rating), Count = g.Count() })
                .FirstOrDefaultAsync();

            return new CourseDto(
                course.Id,
                course.Title,
                course.ShortDescription,
                course.Price,
                course.DurationWeeks,
                course.DifficultyLevel.ToString(),
                course.ImageUrl,
                course.IsActive,
                course.IsFeatured,
                course.CategoryId,
                course.Category.Name,
                course.InstructorId,
                $"{course.Instructor.FirstName} {course.Instructor.LastName}",
                reviewStats?.Avg ?? 0,
                reviewStats?.Count ?? 0,
                course.CreatedAt
            );
        }

        public async Task DeleteAsync(Guid id)
        {
            var course = await _context.Courses.FindAsync(id);
            if (course == null)
                throw new NotFoundException($"Course with ID {id} not found.");

            course.IsActive = false;
            course.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Course '{Title}' (ID {Id}) soft deleted", course.Title, course.Id);
        }

        public async Task<List<CourseDto>> GetInstructorCoursesAsync(string instructorId)
        {
            return await _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .Where(c => c.InstructorId == instructorId)
                .Select(c => new CourseDto(
                    c.Id,
                    c.Title,
                    c.ShortDescription,
                    c.Price,
                    c.DurationWeeks,
                    c.DifficultyLevel.ToString(),
                    c.ImageUrl,
                    c.IsActive,
                    c.IsFeatured,
                    c.CategoryId,
                    c.Category.Name,
                    c.InstructorId,
                    c.Instructor.FirstName + " " + c.Instructor.LastName,
                    c.Reviews.Where(r => r.IsVisible).Any()
                        ? c.Reviews.Where(r => r.IsVisible).Average(r => (double)r.Rating)
                        : 0,
                    c.Reviews.Count(r => r.IsVisible),
                    c.CreatedAt
                ))
                .ToListAsync();
        }
    }
}
