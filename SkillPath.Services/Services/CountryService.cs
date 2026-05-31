using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs.Country;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class CountryService : ICountryService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CountryService> _logger;

        public CountryService(ApplicationDbContext context, ILogger<CountryService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<CountryDto>> GetAllAsync()
        {
            return await _context.Countries
                .AsNoTracking()
                .OrderBy(c => c.Name)
                .Select(c => new CountryDto(c.Id, c.Name, c.Cities.Count))
                .ToListAsync();
        }

        public async Task<CountryDto> GetByIdAsync(int id)
        {
            var country = await _context.Countries
                .AsNoTracking()
                .Where(c => c.Id == id)
                .Select(c => new CountryDto(c.Id, c.Name, c.Cities.Count))
                .FirstOrDefaultAsync();

            if (country == null)
                throw new NotFoundException($"Country with ID {id} not found.");

            return country;
        }

        public async Task<CountryDto> CreateAsync(CountryCreateRequest request)
        {
            var country = new Country
            {
                Name = request.Name
            };

            _context.Countries.Add(country);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Country '{Name}' created with ID {Id}", country.Name, country.Id);

            return new CountryDto(country.Id, country.Name, 0);
        }

        public async Task<CountryDto> UpdateAsync(int id, CountryCreateRequest request)
        {
            var country = await _context.Countries.FindAsync(id);
            if (country == null)
                throw new NotFoundException($"Country with ID {id} not found.");

            country.Name = request.Name;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Country '{Name}' (ID {Id}) updated", country.Name, country.Id);

            var cityCount = await _context.Cities.CountAsync(c => c.CountryId == id);
            return new CountryDto(country.Id, country.Name, cityCount);
        }

        public async Task DeleteAsync(int id)
        {
            var country = await _context.Countries.FindAsync(id);
            if (country == null)
                throw new NotFoundException($"Country with ID {id} not found.");

            var hasCities = await _context.Cities.AnyAsync(c => c.CountryId == id);
            if (hasCities)
                throw new BusinessException("Nije moguce obrisati drzavu koja ima povezane gradove. Prvo obrisite gradove.");

            _context.Countries.Remove(country);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Country '{Name}' (ID {Id}) deleted", country.Name, country.Id);
        }
    }
}
