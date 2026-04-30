using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkillPath.Model;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CountryController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CountryController> _logger;

    public CountryController(ApplicationDbContext context, ILogger<CountryController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult> GetAll()
    {
        var countries = await _context.Countries
            .AsNoTracking()
            .Select(c => new
            {
                c.Id,
                c.Name
            })
            .OrderBy(c => c.Name)
            .ToListAsync();

        return Ok(countries);
    }
}
