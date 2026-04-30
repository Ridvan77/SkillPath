namespace SkillPath.Services.DTOs.Course
{
    public class CourseSearchRequest
    {
        public string? Search { get; set; }
        public int? CategoryId { get; set; }
        public int? DifficultyLevel { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? InstructorId { get; set; }
        public bool? IsFeatured { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
