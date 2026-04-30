namespace SkillPath.Services.DTOs.Review
{
    public record CourseReviewsDto(
        double AverageRating,
        int TotalCount,
        Dictionary<int, int> RatingDistribution,
        PagedResult<ReviewDto> Reviews
    );
}
