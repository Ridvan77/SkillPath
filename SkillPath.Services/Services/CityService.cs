using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs.City;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class CityService : ICityService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CityService> _logger;

        public CityService(ApplicationDbContext context, ILogger<CityService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<CityDto>> GetAllAsync()
        {
            return await _context.Cities
                .AsNoTracking()
                .Include(c => c.Country)
                .OrderBy(c => c.Name)
                .Select(c => new CityDto(c.Id, c.Name, c.CountryId, c.Country.Name))
                .ToListAsync();
        }

        public async Task<CityDto> GetByIdAsync(int id)
        {
            var city = await _context.Cities
                .AsNoTracking()
                .Include(c => c.Country)
                .Where(c => c.Id == id)
                .Select(c => new CityDto(c.Id, c.Name, c.CountryId, c.Country.Name))
                .FirstOrDefaultAsync();

            if (city == null)
                throw new NotFoundException($"City with ID {id} not found.");

            return city;
        }

        public async Task<List<CityDto>> GetByCountryAsync(int countryId)
        {
            return await _context.Cities
                .AsNoTracking()
                .Include(c => c.Country)
                .Where(c => c.CountryId == countryId)
                .OrderBy(c => c.Name)
                .Select(c => new CityDto(c.Id, c.Name, c.CountryId, c.Country.Name))
                .ToListAsync();
        }

        public async Task<CityDto> CreateAsync(CityCreateRequest request)
        {
            var countryExists = await _context.Countries.AnyAsync(c => c.Id == request.CountryId);
            if (!countryExists)
                throw new BusinessException("Odabrana drzava ne postoji.");

            var city = new City
            {
                Name = request.Name,
                CountryId = request.CountryId
            };

            _context.Cities.Add(city);
            await _context.SaveChangesAsync();

            _logger.LogInformation("City '{Name}' created with ID {Id}", city.Name, city.Id);

            var country = await _context.Countries.FindAsync(request.CountryId);
            return new CityDto(city.Id, city.Name, city.CountryId, country!.Name);
        }

        public async Task<CityDto> UpdateAsync(int id, CityCreateRequest request)
        {
            var city = await _context.Cities.FindAsync(id);
            if (city == null)
                throw new NotFoundException($"City with ID {id} not found.");

            var countryExists = await _context.Countries.AnyAsync(c => c.Id == request.CountryId);
            if (!countryExists)
                throw new BusinessException("Odabrana drzava ne postoji.");

            city.Name = request.Name;
            city.CountryId = request.CountryId;

            await _context.SaveChangesAsync();

            _logger.LogInformation("City '{Name}' (ID {Id}) updated", city.Name, city.Id);

            var country = await _context.Countries.FindAsync(request.CountryId);
            return new CityDto(city.Id, city.Name, city.CountryId, country!.Name);
        }

        public async Task DeleteAsync(int id)
        {
            var city = await _context.Cities.FindAsync(id);
            if (city == null)
                throw new NotFoundException($"City with ID {id} not found.");

            var hasUsers = await _context.Users.AnyAsync(u => u.CityId == id);
            if (hasUsers)
                throw new BusinessException("Nije moguce obrisati grad koji ima povezane korisnike.");

            _context.Cities.Remove(city);
            await _context.SaveChangesAsync();

            _logger.LogInformation("City '{Name}' (ID {Id}) deleted", city.Name, city.Id);
        }
    }
}
