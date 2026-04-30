namespace SkillPath.Model.Entities
{
    public class CourseSchedule
    {
        public Guid Id { get; set; }
        public Guid CourseId { get; set; }
        public DayOfWeek DayOfWeek { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int MaxCapacity { get; set; }
        public int CurrentEnrollment { get; set; }
        public bool IsActive { get; set; } = true;

        // Navigation properties
        public virtual Course Course { get; set; } = null!;
        public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
