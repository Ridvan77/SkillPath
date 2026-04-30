using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Payment
{
    public class PaymentIntentRequest
    {
        [Required]
        public Guid ReservationId { get; set; }
    }
}
