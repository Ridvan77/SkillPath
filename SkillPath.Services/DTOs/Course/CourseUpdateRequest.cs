using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Course
{
    public class CourseUpdateRequest
    {
        [MaxLength(200)]
        public string? Title { get; set; }

        [MaxLength(2000)]
        public string? Description { get; set; }

        [MaxLength(300)]
        public string? ShortDescription { get; set; }

        [Range(0.01, 99999)]
        public decimal? Price { get; set; }

        [Range(1, 104)]
        public int? DurationWeeks { get; set; }

        [Range(0, 2)]
        public int? DifficultyLevel { get; set; }

        public string? ImageUrl { get; set; }

        public bool? IsFeatured { get; set; }

        public int? CategoryId { get; set; }

        public string? InstructorId { get; set; }
    }
}
