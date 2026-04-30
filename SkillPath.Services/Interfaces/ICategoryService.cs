using SkillPath.Services.DTOs.Category;

namespace SkillPath.Services.Interfaces;

public interface ICategoryService
{
    Task<List<CategoryDto>> GetAllAsync();
    Task<CategoryDto> GetByIdAsync(int id);
    Task<CategoryDto> CreateAsync(CategoryCreateRequest request);
    Task<CategoryDto> UpdateAsync(int id, CategoryCreateRequest request);
    Task DeleteAsync(int id);
}
