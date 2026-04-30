using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Auth
{
    public class RegisterRequest
    {
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
        [MinLength(4)]
        public string Password { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }

        public int? CityId { get; set; }
    }
}
