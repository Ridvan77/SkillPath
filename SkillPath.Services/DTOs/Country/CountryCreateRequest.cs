using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Country
{
    public class CountryCreateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
    }
}
