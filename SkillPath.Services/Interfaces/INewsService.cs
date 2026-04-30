using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.News;

namespace SkillPath.Services.Interfaces;

public interface INewsService
{
    Task<PagedResult<NewsDto>> GetAllAsync(int page, int pageSize);
    Task<NewsDto> GetByIdAsync(Guid id);
    Task<NewsDto> CreateAsync(string userId, NewsCreateRequest request);
    Task<NewsDto> UpdateAsync(Guid id, NewsCreateRequest request);
    Task DeleteAsync(Guid id);
}
