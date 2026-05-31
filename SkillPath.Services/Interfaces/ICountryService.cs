using SkillPath.Services.DTOs.Country;

namespace SkillPath.Services.Interfaces;

public interface ICountryService
{
    Task<List<CountryDto>> GetAllAsync();
    Task<CountryDto> GetByIdAsync(int id);
    Task<CountryDto> CreateAsync(CountryCreateRequest request);
    Task<CountryDto> UpdateAsync(int id, CountryCreateRequest request);
    Task DeleteAsync(int id);
}
