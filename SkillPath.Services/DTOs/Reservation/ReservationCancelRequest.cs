using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Reservation
{
    public class ReservationCancelRequest
    {
        [MaxLength(500)]
        public string Reason { get; set; } = string.Empty;
    }
}
