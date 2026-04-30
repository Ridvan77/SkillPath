using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Course
{
    public class CourseCreateRequest
    {
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string? Description { get; set; }

        [Required]
        [MaxLength(300)]
        public string ShortDescription { get; set; } = string.Empty;

        [Required]
        [Range(0.01, 99999)]
        public decimal Price { get; set; }

        [Required]
        [Range(1, 104)]
        public int DurationWeeks { get; set; }

        [Required]
        [Range(0, 2)]
        public int DifficultyLevel { get; set; }

        public string? ImageUrl { get; set; }

        public bool IsFeatured { get; set; }

        [Required]
        public int CategoryId { get; set; }

        [Required]
        public string InstructorId { get; set; } = string.Empty;
    }
}
