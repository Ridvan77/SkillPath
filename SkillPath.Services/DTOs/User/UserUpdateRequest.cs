using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.User
{
    public class UserUpdateRequest
    {
        [MaxLength(50)]
        public string? FirstName { get; set; }

        [MaxLength(50)]
        public string? LastName { get; set; }

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public int? CityId { get; set; }

        public bool? IsActive { get; set; }
    }
}
