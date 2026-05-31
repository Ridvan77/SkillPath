using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Payment
{
    public class CreateCheckoutRequest
    {
        [Required]
        public Guid ReservationId { get; set; }

        public string? Name { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public string? Country { get; set; }
        public string? ZipCode { get; set; }
    }
}
