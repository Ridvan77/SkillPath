using System.ComponentModel.DataAnnotations;

namespace SkillPath.Services.DTOs.Review
{
    public class CreateReviewRequest
    {
        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [Required]
        [MaxLength(1000)]
        public string Comment { get; set; } = string.Empty;
    }
}
