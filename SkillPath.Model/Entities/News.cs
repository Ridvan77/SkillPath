namespace SkillPath.Model.Entities
{
    public class News
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string CreatedById { get; set; } = string.Empty;

        // Navigation properties
        public virtual ApplicationUser CreatedBy { get; set; } = null!;
    }
}
