using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Review;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class ReviewService : IReviewService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ReviewService> _logger;

        public ReviewService(ApplicationDbContext context, ILogger<ReviewService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<CourseReviewsDto> GetCourseReviewsAsync(Guid courseId, string? currentUserId, int page, int pageSize, bool includeHidden = false)
        {
            var courseExists = await _context.Courses.AnyAsync(c => c.Id == courseId);
            if (!courseExists)
                throw new NotFoundException($"Course with ID {courseId} not found.");

            var reviewsQuery = _context.Reviews
                .Include(r => r.User)
                .Where(r => r.CourseId == courseId && (includeHidden || r.IsVisible));

            var totalCount = await reviewsQuery.CountAsync();
            var averageRating = totalCount > 0
                ? await reviewsQuery.AverageAsync(r => (double)r.Rating)
                : 0;

            var ratingDistribution = await reviewsQuery
                .GroupBy(r => r.Rating)
                .Select(g => new { Rating = g.Key, Count = g.Count() })
                .ToListAsync();

            var distribution = new Dictionary<int, int>
            {
                { 1, 0 }, { 2, 0 }, { 3, 0 }, { 4, 0 }, { 5, 0 }
            };
            foreach (var rd in ratingDistribution)
            {
                distribution[rd.Rating] = rd.Count;
            }

            var currentUserVoteIds = new HashSet<Guid>();
            if (!string.IsNullOrEmpty(currentUserId))
            {
                currentUserVoteIds = (await _context.ReviewHelpfulVotes
                    .Where(v => v.UserId == currentUserId && v.Review.CourseId == courseId)
                    .Select(v => v.ReviewId)
                    .ToListAsync())
                    .ToHashSet();
            }

            var reviews = await reviewsQuery
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new ReviewDto(
                    r.Id,
                    r.UserId,
                    r.User.FirstName + " " + r.User.LastName,
                    r.CourseId,
                    r.Rating,
                    r.Comment,
                    r.CreatedAt,
                    r.IsVisible,
                    r.HelpfulCount,
                    false
                ))
                .ToListAsync();

            var reviewsWithVoteStatus = reviews.Select(r => r with
            {
                IsHelpfulByCurrentUser = currentUserVoteIds.Contains(r.Id)
            }).ToList();

            var pagedReviews = new PagedResult<ReviewDto>(reviewsWithVoteStatus, page, pageSize, totalCount);

            return new CourseReviewsDto(averageRating, totalCount, distribution, pagedReviews);
        }

        public async Task<ReviewDto> CreateAsync(string userId, Guid courseId, CreateReviewRequest request)
        {
            var canReview = await CanUserReviewAsync(userId, courseId);
            if (!canReview)
                throw new BusinessException("You cannot review this course. You must have a completed reservation and no existing review.");

            var existingReview = await _context.Reviews
                .AnyAsync(r => r.UserId == userId && r.CourseId == courseId);

            if (existingReview)
                throw new BusinessException("You have already reviewed this course.");

            var review = new Review
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CourseId = courseId,
                Rating = request.Rating,
                Comment = request.Comment,
                CreatedAt = DateTime.UtcNow,
                IsVisible = true
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            var user = await _context.Users.FindAsync(userId);

            _logger.LogInformation("Review created by user {UserId} for course {CourseId}, rating {Rating}",
                userId, courseId, request.Rating);

            return new ReviewDto(
                review.Id,
                review.UserId,
                user != null ? $"{user.FirstName} {user.LastName}" : string.Empty,
                review.CourseId,
                review.Rating,
                review.Comment,
                review.CreatedAt,
                review.IsVisible,
                0,
                false
            );
        }

        public async Task DeleteAsync(Guid reviewId, string userId, bool isAdmin)
        {
            var review = await _context.Reviews.FindAsync(reviewId);
            if (review == null)
                throw new NotFoundException($"Review with ID {reviewId} not found.");

            if (!isAdmin && review.UserId != userId)
                throw new BusinessException("You can only delete your own reviews.");

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Review {ReviewId} deleted by user {UserId}", reviewId, userId);
        }

        public async Task<ReviewDto> ToggleVisibilityAsync(Guid reviewId)
        {
            var review = await _context.Reviews
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == reviewId);

            if (review == null)
                throw new NotFoundException($"Review with ID {reviewId} not found.");

            review.IsVisible = !review.IsVisible;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Review {ReviewId} visibility toggled to {IsVisible}", reviewId, review.IsVisible);

            return new ReviewDto(
                review.Id,
                review.UserId,
                $"{review.User.FirstName} {review.User.LastName}",
                review.CourseId,
                review.Rating,
                review.Comment,
                review.CreatedAt,
                review.IsVisible,
                review.HelpfulCount,
                false
            );
        }

        public async Task VoteHelpfulAsync(Guid reviewId, string userId)
        {
            var review = await _context.Reviews.FindAsync(reviewId);
            if (review == null)
                throw new NotFoundException($"Review with ID {reviewId} not found.");

            var existingVote = await _context.ReviewHelpfulVotes
                .FirstOrDefaultAsync(v => v.ReviewId == reviewId && v.UserId == userId);

            if (existingVote != null)
            {
                _context.ReviewHelpfulVotes.Remove(existingVote);
                review.HelpfulCount = Math.Max(0, review.HelpfulCount - 1);
                _logger.LogInformation("Helpful vote removed by user {UserId} for review {ReviewId}", userId, reviewId);
            }
            else
            {
                var vote = new ReviewHelpfulVote
                {
                    Id = Guid.NewGuid(),
                    ReviewId = reviewId,
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.ReviewHelpfulVotes.Add(vote);
                review.HelpfulCount++;
                _logger.LogInformation("Helpful vote added by user {UserId} for review {ReviewId}", userId, reviewId);
            }

            await _context.SaveChangesAsync();
        }

        public async Task<bool> CanUserReviewAsync(string userId, Guid courseId)
        {
            var hasCompletedReservation = await _context.Reservations
                .AnyAsync(r =>
                    r.UserId == userId &&
                    r.Status == ReservationStatus.Completed &&
                    r.CourseSchedule.CourseId == courseId);

            if (!hasCompletedReservation)
                return false;

            var hasExistingReview = await _context.Reviews
                .AnyAsync(r => r.UserId == userId && r.CourseId == courseId);

            return !hasExistingReview;
        }
    }
}
