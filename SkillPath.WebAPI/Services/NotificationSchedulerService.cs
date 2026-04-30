using SkillPath.Services.Interfaces;
using SkillPath.Services.Services;

namespace SkillPath.WebAPI.Services
{
    public class NotificationSchedulerService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<NotificationSchedulerService> _logger;

        public NotificationSchedulerService(IServiceProvider serviceProvider, ILogger<NotificationSchedulerService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Notification scheduler service started");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using var scope = _serviceProvider.CreateScope();
                    var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                    var firebaseService = scope.ServiceProvider.GetRequiredService<IFirebaseService>();

                    var sent = await notificationService.SendScheduledNotificationsAsync();
                    foreach (var s in sent)
                    {
                        try
                        {
                            await firebaseService.SendToGroupAsync(s.TargetGroup, s.Title, s.Content);
                            _logger.LogInformation("FCM push sent for scheduled notification '{Title}'", s.Title);
                        }
                        catch (Exception fcmEx)
                        {
                            _logger.LogWarning(fcmEx, "Failed to send FCM for scheduled notification '{Title}'", s.Title);
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in notification scheduler");
                }

                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
