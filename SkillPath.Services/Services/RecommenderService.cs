using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs.Recommender;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class RecommenderService : IRecommenderService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<RecommenderService> _logger;

        public RecommenderService(ApplicationDbContext context, ILogger<RecommenderService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task TrackCourseViewAsync(string userId, Guid courseId)
        {
            var view = new UserCourseView
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CourseId = courseId,
                ViewedAt = DateTime.UtcNow
            };

            _context.UserCourseViews.Add(view);
            await _context.SaveChangesAsync();
        }

        public async Task<List<RecommendationDto>> GetRecommendationsAsync(string userId, int count = 10)
        {
            var userVector = await BuildUserVectorAsync(userId);

            // Get courses the user has already RESERVED (don't recommend these)
            var reservedCourseIds = await _context.Reservations
                .Where(r => r.UserId == userId &&
                           (r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed))
                .Select(r => r.CourseSchedule.CourseId)
                .Distinct()
                .ToListAsync();
            var reservedSet = reservedCourseIds.ToHashSet();

            // Build vectors for all other active users
            var allUserIds = await _context.Users
                .Where(u => u.Id != userId && u.IsActive)
                .Select(u => u.Id)
                .ToListAsync();

            var allVectors = new Dictionary<string, Dictionary<Guid, double>>();
            foreach (var otherUserId in allUserIds)
            {
                var otherVector = await BuildUserVectorAsync(otherUserId);
                if (otherVector.Count > 0)
                    allVectors[otherUserId] = otherVector;
            }

            var courseScores = new Dictionary<Guid, double>();
            var courseExplanations = new Dictionary<Guid, string>();

            if (userVector.Count >= 1 && allVectors.Any())
            {
                // User-based Collaborative Filtering
                var neighborScores = allVectors
                    .Select(kv => (UserId: kv.Key, Similarity: CosineSimilarity(userVector, kv.Value), Vector: kv.Value))
                    .Where(n => n.Similarity > 0)
                    .OrderByDescending(n => n.Similarity)
                    .Take(10)
                    .ToList();

                foreach (var neighbor in neighborScores)
                {
                    foreach (var kvp in neighbor.Vector)
                    {
                        // Skip courses user already reserved
                        if (reservedSet.Contains(kvp.Key)) continue;

                        if (!courseScores.ContainsKey(kvp.Key))
                        {
                            courseScores[kvp.Key] = 0;
                            courseExplanations[kvp.Key] = "Slicni korisnici sa istim interesima su upisali ovaj kurs";
                        }

                        courseScores[kvp.Key] += neighbor.Similarity * kvp.Value;
                    }
                }
            }

            // If collaborative filtering didn't produce enough results,
            // fill with popularity-based scores from ALL users' interactions
            if (courseScores.Count < count)
            {
                // Aggregate all users' interaction scores per course
                foreach (var kv in allVectors)
                {
                    foreach (var courseKv in kv.Value)
                    {
                        if (reservedSet.Contains(courseKv.Key)) continue;
                        if (courseScores.ContainsKey(courseKv.Key)) continue; // don't override CF scores

                        courseScores.TryAdd(courseKv.Key, 0);
                        courseExplanations.TryAdd(courseKv.Key, "Popularan kurs medju nasim studentima");
                    }
                }

                // For popularity-only courses, score by total interactions across users
                var popularityScores = new Dictionary<Guid, double>();
                foreach (var kv in allVectors)
                {
                    foreach (var courseKv in kv.Value)
                    {
                        popularityScores.TryAdd(courseKv.Key, 0);
                        popularityScores[courseKv.Key] += courseKv.Value;
                    }
                }

                foreach (var kvp in popularityScores)
                {
                    if (!courseScores.ContainsKey(kvp.Key) || courseScores[kvp.Key] == 0)
                    {
                        courseScores[kvp.Key] = kvp.Value * 0.1; // lower weight than CF
                        courseExplanations.TryAdd(kvp.Key, "Popularan kurs medju nasim studentima");
                    }
                }
            }

            // Remove courses user already reserved
            foreach (var id in reservedSet)
                courseScores.Remove(id);

            var topCourseIds = courseScores
                .OrderByDescending(c => c.Value)
                .Take(count)
                .Select(c => c.Key)
                .ToList();

            var courses = await _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .Where(c => topCourseIds.Contains(c.Id) && c.IsActive)
                .ToListAsync();

            var recommendations = new List<RecommendationDto>();
            foreach (var courseId in topCourseIds)
            {
                var course = courses.FirstOrDefault(c => c.Id == courseId);
                if (course == null) continue;

                var reviewStats = await _context.Reviews
                    .Where(r => r.CourseId == courseId && r.IsVisible)
                    .GroupBy(r => r.CourseId)
                    .Select(g => new { Avg = g.Average(r => (double)r.Rating), Count = g.Count() })
                    .FirstOrDefaultAsync();

                recommendations.Add(new RecommendationDto(
                    course.Id,
                    course.Title,
                    course.ShortDescription,
                    course.Price,
                    course.DifficultyLevel.ToString(),
                    course.ImageUrl,
                    course.Category.Name,
                    $"{course.Instructor.FirstName} {course.Instructor.LastName}",
                    reviewStats?.Avg ?? 0,
                    reviewStats?.Count ?? 0,
                    courseScores[courseId],
                    courseExplanations.GetValueOrDefault(courseId, "Preporuceno za vas")
                ));
            }

            _logger.LogInformation("Generated {Count} recommendations for user {UserId} (CF: {CFCount}, Popularity fill: {PopCount})",
                recommendations.Count, userId,
                recommendations.Count(r => r.Explanation.Contains("Slicni")),
                recommendations.Count(r => r.Explanation.Contains("Popularan")));

            return recommendations;
        }

        private async Task<Dictionary<Guid, double>> BuildUserVectorAsync(string userId)
        {
            var vector = new Dictionary<Guid, double>();

            // Views: +1 each, capped at 3
            var views = await _context.UserCourseViews
                .Where(v => v.UserId == userId)
                .GroupBy(v => v.CourseId)
                .Select(g => new { CourseId = g.Key, Count = g.Count() })
                .ToListAsync();

            foreach (var v in views)
            {
                var score = Math.Min(v.Count, 3);
                vector[v.CourseId] = score;
            }

            // Favorites: +2
            var favorites = await _context.UserFavorites
                .Where(f => f.UserId == userId)
                .Select(f => f.CourseId)
                .ToListAsync();

            foreach (var courseId in favorites)
            {
                vector.TryAdd(courseId, 0);
                vector[courseId] += 2;
            }

            // Reservations (Active or Completed): +5
            var reservedCourseIds = await _context.Reservations
                .Where(r => r.UserId == userId &&
                           (r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed))
                .Select(r => r.CourseSchedule.CourseId)
                .Distinct()
                .ToListAsync();

            foreach (var courseId in reservedCourseIds)
            {
                vector.TryAdd(courseId, 0);
                vector[courseId] += 5;
            }

            // Reviews: +rating
            var reviews = await _context.Reviews
                .Where(r => r.UserId == userId)
                .Select(r => new { r.CourseId, r.Rating })
                .ToListAsync();

            foreach (var review in reviews)
            {
                vector.TryAdd(review.CourseId, 0);
                vector[review.CourseId] += review.Rating;
            }

            return vector;
        }

        private async Task<List<RecommendationDto>> GetPopularityBasedRecommendationsAsync(string userId, int count)
        {
            var userInteractedCourseIds = await _context.UserCourseViews
                .Where(v => v.UserId == userId)
                .Select(v => v.CourseId)
                .Union(_context.UserFavorites.Where(f => f.UserId == userId).Select(f => f.CourseId))
                .Union(_context.Reservations
                    .Where(r => r.UserId == userId)
                    .Select(r => r.CourseSchedule.CourseId))
                .Distinct()
                .ToListAsync();

            var courses = await _context.Courses
                .Include(c => c.Category)
                .Include(c => c.Instructor)
                .Where(c => c.IsActive && !userInteractedCourseIds.Contains(c.Id))
                .Select(c => new
                {
                    Course = c,
                    ReservationCount = c.Schedules.SelectMany(s => s.Reservations)
                        .Count(r => r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed),
                    AvgRating = c.Reviews.Where(r => r.IsVisible).Any()
                        ? c.Reviews.Where(r => r.IsVisible).Average(r => (double)r.Rating)
                        : 0,
                    ReviewCount = c.Reviews.Count(r => r.IsVisible)
                })
                .OrderByDescending(c => c.ReservationCount)
                .ThenByDescending(c => c.AvgRating)
                .Take(count)
                .ToListAsync();

            return courses.Select(c => new RecommendationDto(
                c.Course.Id,
                c.Course.Title,
                c.Course.ShortDescription,
                c.Course.Price,
                c.Course.DifficultyLevel.ToString(),
                c.Course.ImageUrl,
                c.Course.Category.Name,
                $"{c.Course.Instructor.FirstName} {c.Course.Instructor.LastName}",
                c.AvgRating,
                c.ReviewCount,
                c.ReservationCount + c.AvgRating,
                "Popular course you might enjoy"
            )).ToList();
        }

        private static double CosineSimilarity(Dictionary<Guid, double> vectorA, Dictionary<Guid, double> vectorB)
        {
            var allKeys = vectorA.Keys.Union(vectorB.Keys);

            double dotProduct = 0;
            double magnitudeA = 0;
            double magnitudeB = 0;

            foreach (var key in allKeys)
            {
                var a = vectorA.GetValueOrDefault(key, 0);
                var b = vectorB.GetValueOrDefault(key, 0);

                dotProduct += a * b;
                magnitudeA += a * a;
                magnitudeB += b * b;
            }

            if (magnitudeA == 0 || magnitudeB == 0)
                return 0;

            return dotProduct / (Math.Sqrt(magnitudeA) * Math.Sqrt(magnitudeB));
        }
    }
}
