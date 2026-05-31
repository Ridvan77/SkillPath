using SkillPath.Services.DTOs.City;

namespace SkillPath.Services.Interfaces;

public interface ICityService
{
    Task<List<CityDto>> GetAllAsync();
    Task<CityDto> GetByIdAsync(int id);
    Task<List<CityDto>> GetByCountryAsync(int countryId);
    Task<CityDto> CreateAsync(CityCreateRequest request);
    Task<CityDto> UpdateAsync(int id, CityCreateRequest request);
    Task DeleteAsync(int id);
}
