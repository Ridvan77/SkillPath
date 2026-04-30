using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.User;

namespace SkillPath.Services.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetAllAsync(int page, int pageSize, string? search, string? role);
    Task<UserDto> GetByIdAsync(string id);
    Task<UserDto> UpdateAsync(string id, UserUpdateRequest request);
    Task ToggleActiveAsync(string id);
    Task DeleteAsync(string id);
}
