using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkillPath.Model;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CityController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CityController> _logger;

    public CityController(ApplicationDbContext context, ILogger<CityController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult> GetAll()
    {
        var cities = await _context.Cities
            .AsNoTracking()
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.CountryId,
                CountryName = c.Country.Name
            })
            .OrderBy(c => c.Name)
            .ToListAsync();

        return Ok(cities);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult> GetById(int id)
    {
        var city = await _context.Cities
            .AsNoTracking()
            .Where(c => c.Id == id)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.CountryId,
                CountryName = c.Country.Name
            })
            .FirstOrDefaultAsync();

        if (city == null)
            return NotFound();

        return Ok(city);
    }
}
