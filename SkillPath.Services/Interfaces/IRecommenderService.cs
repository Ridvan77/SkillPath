using SkillPath.Services.DTOs.Recommender;

namespace SkillPath.Services.Interfaces;

public interface IRecommenderService
{
    Task<List<RecommendationDto>> GetRecommendationsAsync(string userId, int count = 10);
    Task TrackCourseViewAsync(string userId, Guid courseId);
}
