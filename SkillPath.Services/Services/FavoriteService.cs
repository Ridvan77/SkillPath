using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Course;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class FavoriteService : IFavoriteService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<FavoriteService> _logger;

        public FavoriteService(ApplicationDbContext context, ILogger<FavoriteService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<bool> ToggleFavoriteAsync(string userId, Guid courseId)
        {
            var existing = await _context.UserFavorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.CourseId == courseId);

            if (existing != null)
            {
                _context.UserFavorites.Remove(existing);
                await _context.SaveChangesAsync();
                _logger.LogInformation("User {UserId} removed course {CourseId} from favorites", userId, courseId);
                return false;
            }

            var favorite = new UserFavorite
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CourseId = courseId,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserFavorites.Add(favorite);
            await _context.SaveChangesAsync();
            _logger.LogInformation("User {UserId} added course {CourseId} to favorites", userId, courseId);
            return true;
        }

        public async Task<PagedResult<CourseDto>> GetUserFavoritesAsync(string userId, int page, int pageSize)
        {
            var query = _context.UserFavorites
                .Where(f => f.UserId == userId)
                .Include(f => f.Course)
                    .ThenInclude(c => c.Category)
                .Include(f => f.Course)
                    .ThenInclude(c => c.Instructor)
                .Where(f => f.Course.IsActive);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(f => new CourseDto(
                    f.Course.Id,
                    f.Course.Title,
                    f.Course.ShortDescription,
                    f.Course.Price,
                    f.Course.DurationWeeks,
                    f.Course.DifficultyLevel.ToString(),
                    f.Course.ImageUrl,
                    f.Course.IsActive,
                    f.Course.IsFeatured,
                    f.Course.CategoryId,
                    f.Course.Category.Name,
                    f.Course.InstructorId,
                    f.Course.Instructor.FirstName + " " + f.Course.Instructor.LastName,
                    f.Course.Reviews.Where(r => r.IsVisible).Any()
                        ? f.Course.Reviews.Where(r => r.IsVisible).Average(r => (double)r.Rating)
                        : 0,
                    f.Course.Reviews.Count(r => r.IsVisible),
                    f.Course.CreatedAt
                ))
                .ToListAsync();

            return new PagedResult<CourseDto>(items, page, pageSize, totalCount);
        }

        public async Task<bool> IsFavoriteAsync(string userId, Guid courseId)
        {
            return await _context.UserFavorites
                .AnyAsync(f => f.UserId == userId && f.CourseId == courseId);
        }
    }
}
