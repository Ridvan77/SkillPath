using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkillPath.Model;
using SkillPath.Model.Enums;

namespace SkillPath.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class DashboardController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(ApplicationDbContext context, ILogger<DashboardController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet("stats")]
    public async Task<ActionResult> GetStats()
    {
        var totalCourses = await _context.Courses.CountAsync(c => c.IsActive);

        var studentRoleId = await _context.Roles
            .Where(r => r.Name == "Student")
            .Select(r => r.Id)
            .FirstOrDefaultAsync();

        var activeStudents = studentRoleId != null
            ? await _context.UserRoles
                .Where(ur => ur.RoleId == studentRoleId)
                .Join(_context.Users.Where(u => u.IsActive), ur => ur.UserId, u => u.Id, (ur, u) => u)
                .CountAsync()
            : 0;

        // Calculate revenue from payments if available, otherwise from confirmed reservations
        var paymentRevenue = await _context.Payments
            .Where(p => p.Status == PaymentStatus.Succeeded)
            .SumAsync(p => (decimal?)p.Amount) ?? 0;

        var totalRevenue = paymentRevenue > 0
            ? paymentRevenue
            : await _context.Reservations
                .Where(r => r.Status == ReservationStatus.Active || r.Status == ReservationStatus.Completed)
                .SumAsync(r => (decimal?)r.TotalAmount) ?? 0;

        var averageRating = await _context.Reviews
            .Where(r => r.IsVisible)
            .AverageAsync(r => (double?)r.Rating) ?? 0;

        var recentReservations = await _context.Reservations
            .AsNoTracking()
            .OrderByDescending(r => r.CreatedAt)
            .Take(10)
            .Select(r => new
            {
                id = r.Id.ToString(),
                r.ReservationCode,
                r.FirstName,
                r.LastName,
                r.Email,
                r.TotalAmount,
                status = r.Status.ToString(),
                r.CreatedAt
            })
            .ToListAsync();

        return Ok(new
        {
            totalCourses,
            activeStudents,
            totalRevenue,
            averageRating = Math.Round(averageRating, 2),
            recentReservations
        });
    }
}
