using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Reservation
{
    public class ReservationCreateRequest
    {
        [Required]
        public Guid CourseScheduleId { get; set; }

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string PhoneNumber { get; set; } = string.Empty;
    }
}
