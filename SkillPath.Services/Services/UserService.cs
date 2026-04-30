using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.User;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UserService> _logger;
        private readonly UserManager<ApplicationUser> _userManager;

        public UserService(
            ApplicationDbContext context,
            ILogger<UserService> logger,
            UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _logger = logger;
            _userManager = userManager;
        }

        public async Task<PagedResult<UserDto>> GetAllAsync(int page, int pageSize, string? search, string? role)
        {
            var query = _context.Users
                .Include(u => u.City)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.ToLower();
                query = query.Where(u =>
                    u.FirstName.ToLower().Contains(s) ||
                    u.LastName.ToLower().Contains(s) ||
                    (u.Email != null && u.Email.ToLower().Contains(s)));
            }

            if (!string.IsNullOrWhiteSpace(role))
            {
                var roleId = await _context.Roles
                    .Where(r => r.NormalizedName == role.ToUpper())
                    .Select(r => r.Id)
                    .FirstOrDefaultAsync();

                if (roleId != null)
                {
                    var userIdsInRole = _context.UserRoles
                        .Where(ur => ur.RoleId == roleId)
                        .Select(ur => ur.UserId);

                    query = query.Where(u => userIdsInRole.Contains(u.Id));
                }
                else
                {
                    query = query.Where(u => false);
                }
            }

            var totalCount = await query.CountAsync();

            var users = await query
                .OrderByDescending(u => u.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = new List<UserDto>();
            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                var reservationCount = await _context.Reservations.CountAsync(r => r.UserId == user.Id);

                items.Add(new UserDto(
                    user.Id,
                    user.FirstName,
                    user.LastName,
                    user.Email ?? string.Empty,
                    user.PhoneNumber,
                    user.ProfileImageUrl,
                    user.CityId,
                    user.City?.Name,
                    roles.ToList(),
                    user.IsActive,
                    user.CreatedAt,
                    user.LastLoginAt,
                    reservationCount
                ));
            }

            return new PagedResult<UserDto>(items, page, pageSize, totalCount);
        }

        public async Task<UserDto> GetByIdAsync(string id)
        {
            var user = await _context.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
                throw new NotFoundException($"User with ID {id} not found.");

            var roles = await _userManager.GetRolesAsync(user);
            var reservationCount = await _context.Reservations.CountAsync(r => r.UserId == user.Id);

            return new UserDto(
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email ?? string.Empty,
                user.PhoneNumber,
                user.ProfileImageUrl,
                user.CityId,
                user.City?.Name,
                roles.ToList(),
                user.IsActive,
                user.CreatedAt,
                user.LastLoginAt,
                reservationCount
            );
        }

        public async Task<UserDto> UpdateAsync(string id, UserUpdateRequest request)
        {
            var user = await _context.Users
                .Include(u => u.City)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
                throw new NotFoundException($"User with ID {id} not found.");

            if (request.FirstName != null) user.FirstName = request.FirstName;
            if (request.LastName != null) user.LastName = request.LastName;
            if (request.PhoneNumber != null) user.PhoneNumber = request.PhoneNumber;
            if (request.CityId.HasValue) user.CityId = request.CityId.Value;
            if (request.IsActive.HasValue) user.IsActive = request.IsActive.Value;

            await _context.SaveChangesAsync();

            _logger.LogInformation("User {Id} updated", id);

            var roles = await _userManager.GetRolesAsync(user);
            var reservationCount = await _context.Reservations.CountAsync(r => r.UserId == user.Id);

            await _context.Entry(user).Reference(u => u.City).LoadAsync();

            return new UserDto(
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email ?? string.Empty,
                user.PhoneNumber,
                user.ProfileImageUrl,
                user.CityId,
                user.City?.Name,
                roles.ToList(),
                user.IsActive,
                user.CreatedAt,
                user.LastLoginAt,
                reservationCount
            );
        }

        public async Task ToggleActiveAsync(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new NotFoundException($"User with ID {id} not found.");

            user.IsActive = !user.IsActive;
            await _context.SaveChangesAsync();

            _logger.LogInformation("User {Id} active status toggled to {IsActive}", id, user.IsActive);
        }

        public async Task DeleteAsync(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                throw new NotFoundException($"User with ID {id} not found.");

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            _logger.LogInformation("User {Id} permanently deleted", id);
        }
    }
}
