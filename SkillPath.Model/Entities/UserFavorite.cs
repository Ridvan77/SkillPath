namespace SkillPath.Model.Entities
{
    public class UserFavorite
    {
        public Guid Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public Guid CourseId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ApplicationUser User { get; set; } = null!;
        public virtual Course Course { get; set; } = null!;
    }
}
