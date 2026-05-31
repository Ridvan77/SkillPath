using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.City
{
    public class CityCreateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public int CountryId { get; set; }
    }
}
