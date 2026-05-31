using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkillPath.Services.DTOs.City;
using SkillPath.Services.Interfaces;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CityController : ControllerBase
{
    private readonly ICityService _cityService;
    private readonly ILogger<CityController> _logger;

    public CityController(ICityService cityService, ILogger<CityController> logger)
    {
        _cityService = cityService;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<List<CityDto>>> GetAll()
    {
        var result = await _cityService.GetAllAsync();
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<CityDto>> GetById(int id)
    {
        var result = await _cityService.GetByIdAsync(id);
        return Ok(result);
    }

    [HttpGet("country/{countryId:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<List<CityDto>>> GetByCountry(int countryId)
    {
        var result = await _cityService.GetByCountryAsync(countryId);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CityDto>> Create([FromBody] CityCreateRequest request)
    {
        var result = await _cityService.CreateAsync(request);
        _logger.LogInformation("City {CityId} created.", result.Id);
        return Created(string.Empty, result);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CityDto>> Update(int id, [FromBody] CityCreateRequest request)
    {
        var result = await _cityService.UpdateAsync(id, request);
        _logger.LogInformation("City {CityId} updated.", id);
        return Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> Delete(int id)
    {
        await _cityService.DeleteAsync(id);
        _logger.LogInformation("City {CityId} deleted.", id);
        return NoContent();
    }
}
