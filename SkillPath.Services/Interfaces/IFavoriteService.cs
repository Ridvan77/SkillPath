using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Course;

namespace SkillPath.Services.Interfaces;

public interface IFavoriteService
{
    Task<PagedResult<CourseDto>> GetUserFavoritesAsync(string userId, int page, int pageSize);
    Task<bool> ToggleFavoriteAsync(string userId, Guid courseId);
    Task<bool> IsFavoriteAsync(string userId, Guid courseId);
}
