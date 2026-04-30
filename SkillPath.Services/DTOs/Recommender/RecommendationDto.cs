namespace SkillPath.Services.DTOs.Recommender
{
    public record RecommendationDto(
        Guid CourseId,
        string Title,
        string ShortDescription,
        decimal Price,
        string DifficultyLevel,
        string? ImageUrl,
        string CategoryName,
        string InstructorName,
        double AverageRating,
        int ReviewCount,
        double RecommendationScore,
        string Explanation
    );
}
