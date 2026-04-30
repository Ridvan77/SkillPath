namespace SkillPath.Model.Entities
{
    public class ReviewHelpfulVote
    {
        public Guid Id { get; set; }
        public Guid ReviewId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual Review Review { get; set; } = null!;
        public virtual ApplicationUser User { get; set; } = null!;
    }
}
