using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs.Report;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class ReportService : IReportService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ReportService> _logger;

        public ReportService(ApplicationDbContext context, ILogger<ReportService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<InstructorReportResponse> GetInstructorReportAsync(List<string>? instructorIds, DateTime? from, DateTime? to)
        {
            var coursesQuery = _context.Courses
                .Include(c => c.Instructor)
                .Include(c => c.Reviews)
                .Where(c => c.IsActive)
                .AsQueryable();

            if (instructorIds != null && instructorIds.Any())
                coursesQuery = coursesQuery.Where(c => instructorIds.Contains(c.InstructorId));

            var courses = await coursesQuery.ToListAsync();

            var reservationsQuery = _context.Reservations
                .Include(r => r.CourseSchedule)
                .Where(r => r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed);

            if (from.HasValue)
                reservationsQuery = reservationsQuery.Where(r => r.CreatedAt >= from.Value);
            if (to.HasValue)
                reservationsQuery = reservationsQuery.Where(r => r.CreatedAt <= to.Value);

            var reservations = await reservationsQuery.ToListAsync();

            var grouped = courses.GroupBy(c => new { c.InstructorId, c.Instructor.FirstName, c.Instructor.LastName });

            var instructorReports = grouped.Select(g =>
            {
                var courseIds = g.Select(c => c.Id).ToHashSet();
                var matchingReservations = reservations.Where(r => courseIds.Contains(r.CourseSchedule.CourseId)).ToList();
                var visibleReviews = g.SelectMany(c => c.Reviews).Where(r => r.IsVisible).ToList();

                return new InstructorReportDto(
                    g.Key.InstructorId,
                    g.Key.FirstName + " " + g.Key.LastName,
                    g.Count(),
                    matchingReservations.Count,
                    matchingReservations.Sum(r => r.TotalAmount),
                    visibleReviews.Any() ? visibleReviews.Average(r => (double)r.Rating) : 0
                );
            }).ToList();

            var totalStudents = instructorReports.Sum(r => r.TotalStudents);
            var totalRevenue = instructorReports.Sum(r => r.TotalRevenue);

            _logger.LogInformation("Instructor report generated: {Count} instructors, {Students} total students, {Revenue} total revenue",
                instructorReports.Count, totalStudents, totalRevenue);

            return new InstructorReportResponse(
                instructorReports,
                instructorReports.Count,
                totalStudents,
                totalRevenue,
                from,
                to
            );
        }

        public async Task<List<CategoryPopularityReportDto>> GetCategoryPopularityReportAsync(DateTime? from, DateTime? to, List<int>? categoryIds = null)
        {
            var categoriesQuery = _context.Categories
                .Include(cat => cat.Courses)
                    .ThenInclude(c => c.Reviews)
                .AsQueryable();

            if (categoryIds != null && categoryIds.Any())
                categoriesQuery = categoriesQuery.Where(cat => categoryIds.Contains(cat.Id));

            var categories = await categoriesQuery.ToListAsync();

            // Current period reservations
            var reservationsQuery = _context.Reservations
                .Include(r => r.CourseSchedule)
                .Where(r => r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed);

            if (from.HasValue)
                reservationsQuery = reservationsQuery.Where(r => r.CreatedAt >= from.Value);
            if (to.HasValue)
                reservationsQuery = reservationsQuery.Where(r => r.CreatedAt <= to.Value);

            var reservations = await reservationsQuery.ToListAsync();

            // Previous period reservations for growth calculation
            List<Reservation>? previousReservations = null;
            if (from.HasValue && to.HasValue)
            {
                var periodLength = to.Value - from.Value;
                var previousFrom = from.Value - periodLength;
                var previousTo = from.Value;

                previousReservations = await _context.Reservations
                    .Include(r => r.CourseSchedule)
                    .Where(r => (r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed)
                                && r.CreatedAt >= previousFrom && r.CreatedAt < previousTo)
                    .ToListAsync();
            }

            var report = categories.Select(cat =>
            {
                var courseIds = cat.Courses.Where(c => c.IsActive).Select(c => c.Id).ToHashSet();
                var matchingReservations = reservations.Where(r => courseIds.Contains(r.CourseSchedule.CourseId)).ToList();
                var visibleReviews = cat.Courses.SelectMany(c => c.Reviews).Where(r => r.IsVisible).ToList();

                // Growth: compare enrollment count with previous period
                double? growthPercentage = null;
                if (previousReservations != null)
                {
                    var previousCount = previousReservations.Count(r => courseIds.Contains(r.CourseSchedule.CourseId));
                    if (previousCount > 0)
                        growthPercentage = ((double)(matchingReservations.Count - previousCount) / previousCount) * 100;
                    else if (matchingReservations.Count > 0)
                        growthPercentage = 100;
                }

                return new CategoryPopularityReportDto(
                    cat.Id,
                    cat.Name,
                    cat.Courses.Count(c => c.IsActive),
                    matchingReservations.Count,
                    matchingReservations.Sum(r => r.TotalAmount),
                    visibleReviews.Any() ? visibleReviews.Average(r => (double)r.Rating) : 0,
                    growthPercentage
                );
            })
            .OrderByDescending(r => r.EnrollmentCount)
            .ToList();

            _logger.LogInformation("Category popularity report generated for {Count} categories", report.Count);

            return report;
        }
    }
}
