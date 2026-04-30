using SkillPath.Services.DTOs.Review;

namespace SkillPath.Services.Interfaces;

public interface IReviewService
{
    Task<CourseReviewsDto> GetCourseReviewsAsync(Guid courseId, string? currentUserId, int page, int pageSize, bool includeHidden = false);
    Task<ReviewDto> CreateAsync(string userId, Guid courseId, CreateReviewRequest request);
    Task DeleteAsync(Guid reviewId, string userId, bool isAdmin);
    Task<ReviewDto> ToggleVisibilityAsync(Guid reviewId);
    Task VoteHelpfulAsync(Guid reviewId, string userId);
    Task<bool> CanUserReviewAsync(string userId, Guid courseId);
}
