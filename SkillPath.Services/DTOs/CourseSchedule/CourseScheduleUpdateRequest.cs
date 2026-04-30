using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.CourseSchedule
{
    public class CourseScheduleUpdateRequest
    {
        public Guid? CourseId { get; set; }

        [Range(0, 6)]
        public int? DayOfWeek { get; set; }

        public string? StartTime { get; set; }

        public string? EndTime { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Range(1, 100)]
        public int? MaxCapacity { get; set; }
    }
}
