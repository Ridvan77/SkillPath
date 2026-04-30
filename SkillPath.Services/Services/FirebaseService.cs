using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;

namespace SkillPath.Services.Services
{
    public interface IFirebaseService
    {
        Task SendToUserAsync(string userId, string title, string body, Dictionary<string, string>? data = null);
        Task SendToGroupAsync(string targetGroup, string title, string body, Dictionary<string, string>? data = null);
        Task RegisterTokenAsync(string userId, string token, string platform);
    }

    public class FirebaseService : IFirebaseService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<FirebaseService> _logger;

        public FirebaseService(ApplicationDbContext context, ILogger<FirebaseService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SendToUserAsync(string userId, string title, string body, Dictionary<string, string>? data = null)
        {
            var tokens = await _context.FcmTokens
                .Where(t => t.UserId == userId)
                .Select(t => t.Token)
                .ToListAsync();

            if (!tokens.Any()) return;

            await SendToTokensAsync(tokens, title, body, data);
        }

        public async Task SendToGroupAsync(string targetGroup, string title, string body, Dictionary<string, string>? data = null)
        {
            IQueryable<Model.Entities.FcmToken> query = _context.FcmTokens;

            if (targetGroup == "students")
            {
                var studentRoleId = await _context.Roles
                    .Where(r => r.Name == "Student")
                    .Select(r => r.Id)
                    .FirstOrDefaultAsync();
                if (studentRoleId != null)
                {
                    var studentIds = await _context.UserRoles
                        .Where(ur => ur.RoleId == studentRoleId)
                        .Select(ur => ur.UserId)
                        .ToListAsync();
                    query = query.Where(t => studentIds.Contains(t.UserId));
                }
            }
            else if (targetGroup == "instructors")
            {
                var instructorRoleId = await _context.Roles
                    .Where(r => r.Name == "Instructor")
                    .Select(r => r.Id)
                    .FirstOrDefaultAsync();
                if (instructorRoleId != null)
                {
                    var instructorIds = await _context.UserRoles
                        .Where(ur => ur.RoleId == instructorRoleId)
                        .Select(ur => ur.UserId)
                        .ToListAsync();
                    query = query.Where(t => instructorIds.Contains(t.UserId));
                }
            }

            var tokens = await query.Select(t => t.Token).Distinct().ToListAsync();
            if (!tokens.Any()) return;

            await SendToTokensAsync(tokens, title, body, data);
        }

        public async Task RegisterTokenAsync(string userId, string token, string platform)
        {
            // Verify user exists
            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
            {
                _logger.LogWarning("FCM token registration skipped: user {UserId} not found", userId);
                return;
            }

            var existing = await _context.FcmTokens
                .FirstOrDefaultAsync(t => t.Token == token);

            if (existing != null)
            {
                existing.UserId = userId;
                existing.Platform = platform;
                existing.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                _context.FcmTokens.Add(new Model.Entities.FcmToken
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Token = token,
                    Platform = platform,
                });
            }

            await _context.SaveChangesAsync();
            _logger.LogInformation("FCM token registered for user {UserId}", userId);
        }

        private async Task SendToTokensAsync(List<string> tokens, string title, string body, Dictionary<string, string>? data)
        {
            if (FirebaseMessaging.DefaultInstance == null)
            {
                _logger.LogWarning("Firebase not initialized, skipping push notification");
                return;
            }

            // Send in batches of 500 (FCM limit)
            var batches = tokens.Select((t, i) => new { t, i })
                .GroupBy(x => x.i / 500)
                .Select(g => g.Select(x => x.t).ToList());

            foreach (var batch in batches)
            {
                try
                {
                    var message = new MulticastMessage
                    {
                        Tokens = batch,
                        Notification = new Notification
                        {
                            Title = title,
                            Body = body,
                        },
                        Data = data,
                    };

                    var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
                    _logger.LogInformation("FCM sent: {Success}/{Total} successful",
                        response.SuccessCount, batch.Count);

                    // Clean up invalid tokens
                    for (int i = 0; i < response.Responses.Count; i++)
                    {
                        if (!response.Responses[i].IsSuccess &&
                            response.Responses[i].Exception?.MessagingErrorCode == MessagingErrorCode.Unregistered)
                        {
                            var invalidToken = batch[i];
                            var toRemove = await _context.FcmTokens
                                .Where(t => t.Token == invalidToken)
                                .ToListAsync();
                            _context.FcmTokens.RemoveRange(toRemove);
                        }
                    }
                    await _context.SaveChangesAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send FCM batch");
                }
            }
        }
    }
}
