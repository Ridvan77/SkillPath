namespace SkillPath.Model.Entities
{
    public class Review
    {
        public Guid Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public Guid CourseId { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsVisible { get; set; } = true;
        public bool IsReported { get; set; }
        public int ReportCount { get; set; }
        public int HelpfulCount { get; set; }

        // Navigation properties
        public virtual ApplicationUser User { get; set; } = null!;
        public virtual Course Course { get; set; } = null!;
        public virtual ICollection<ReviewHelpfulVote> HelpfulVotes { get; set; } = new List<ReviewHelpfulVote>();
    }
}
