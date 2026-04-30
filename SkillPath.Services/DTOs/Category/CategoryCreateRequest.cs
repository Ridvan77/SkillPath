using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Category
{
    public class CategoryCreateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }
    }
}
