using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.CourseSchedule
{
    public class CourseScheduleCreateRequest
    {
        [Required]
        public Guid CourseId { get; set; }

        [Required]
        [Range(0, 6)]
        public int DayOfWeek { get; set; }

        [Required]
        public string StartTime { get; set; } = string.Empty;

        [Required]
        public string EndTime { get; set; } = string.Empty;

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        [Range(1, 100)]
        public int MaxCapacity { get; set; }
    }
}
