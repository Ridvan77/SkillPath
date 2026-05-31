using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.Country;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CountryController : ControllerBase
{
    private readonly ICountryService _countryService;
    private readonly ILogger<CountryController> _logger;

    public CountryController(ICountryService countryService, ILogger<CountryController> logger)
    {
        _countryService = countryService;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<List<CountryDto>>> GetAll()
    {
        var result = await _countryService.GetAllAsync();
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<CountryDto>> GetById(int id)
    {
        var result = await _countryService.GetByIdAsync(id);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CountryDto>> Create([FromBody] CountryCreateRequest request)
    {
        var result = await _countryService.CreateAsync(request);
        _logger.LogInformation("Country {CountryId} created.", result.Id);
        return Created(string.Empty, result);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CountryDto>> Update(int id, [FromBody] CountryCreateRequest request)
    {
        var result = await _countryService.UpdateAsync(id, request);
        _logger.LogInformation("Country {CountryId} updated.", id);
        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(int id)
    {
        await _countryService.DeleteAsync(id);
        _logger.LogInformation("Country {CountryId} deleted.", id);
        return NoContent();
    }
}
