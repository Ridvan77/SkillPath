using SkillPath.Model.Enums;

namespace SkillPath.Model.Entities
{
    public class Course
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string ShortDescription { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int DurationWeeks { get; set; }
        public DifficultyLevel DifficultyLevel { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsActive { get; set; } = true;
        public bool IsFeatured { get; set; }
        public int CategoryId { get; set; }
        public string InstructorId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public virtual Category Category { get; set; } = null!;
        public virtual ApplicationUser Instructor { get; set; } = null!;
        public virtual ICollection<CourseSchedule> Schedules { get; set; } = new List<CourseSchedule>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<UserFavorite> Favorites { get; set; } = new List<UserFavorite>();
        public virtual ICollection<UserCourseView> Views { get; set; } = new List<UserCourseView>();
    }
}
