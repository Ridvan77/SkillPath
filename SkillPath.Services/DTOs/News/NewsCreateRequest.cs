using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.News
{
    public class NewsCreateRequest
    {
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(5000)]
        public string Content { get; set; } = string.Empty;

        public string? ImageUrl { get; set; }
    }
}
