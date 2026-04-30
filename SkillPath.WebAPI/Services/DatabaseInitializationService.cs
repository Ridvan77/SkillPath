using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SkillPath.Model;
using SkillPath.Model.Entities;

namespace SkillPath.WebAPI.Services
{
    public class DatabaseInitializationService : IHostedService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<DatabaseInitializationService> _logger;

        public DatabaseInitializationService(
            IServiceProvider serviceProvider,
            ILogger<DatabaseInitializationService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("Database initialization starting...");

            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<ApplicationRole>>();

            // Retry migration up to 5 times with exponential backoff
            await MigrateDatabaseAsync(context, cancellationToken);

            // Seed roles
            await SeedRolesAsync(roleManager);

            // Seed main users (admin, student, instructor)
            var adminUser = await SeedMainUsersAsync(userManager);

            // Seed additional data
            await SeedAdditionalDataAsync(context, userManager, adminUser);

            _logger.LogInformation("Database initialization completed successfully.");
        }

        public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        private async Task MigrateDatabaseAsync(ApplicationDbContext context, CancellationToken cancellationToken)
        {
            const int maxRetries = 5;

            for (int retry = 0; retry < maxRetries; retry++)
            {
                try
                {
                    _logger.LogInformation("Applying database setup (attempt {Attempt}/{MaxRetries})...", retry + 1, maxRetries);

                    // Drop and recreate if needed, or create fresh
                    var created = await context.Database.EnsureCreatedAsync(cancellationToken);
                    if (created)
                    {
                        _logger.LogInformation("Database created successfully from model.");
                    }
                    else
                    {
                        _logger.LogInformation("Database already exists.");
                    }

                    _logger.LogInformation("Database setup completed successfully.");
                    return;
                }
                catch (Exception ex) when (retry < maxRetries - 1)
                {
                    var delay = TimeSpan.FromSeconds(Math.Pow(2, retry));
                    _logger.LogWarning(ex, "Database migration failed (attempt {Attempt}/{MaxRetries}). Retrying in {Delay}s...",
                        retry + 1, maxRetries, delay.TotalSeconds);
                    await Task.Delay(delay, cancellationToken);
                }
            }

            // Final attempt - let exception propagate
            await context.Database.MigrateAsync(cancellationToken);
        }

        private async Task SeedRolesAsync(RoleManager<ApplicationRole> roleManager)
        {
            string[] roles = { "Admin", "Instructor", "Student" };

            foreach (var roleName in roles)
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    var result = await roleManager.CreateAsync(new ApplicationRole { Name = roleName });
                    if (result.Succeeded)
                    {
                        _logger.LogInformation("Role '{Role}' created successfully.", roleName);
                    }
                    else
                    {
                        _logger.LogError("Failed to create role '{Role}': {Errors}", roleName,
                            string.Join(", ", result.Errors.Select(e => e.Description)));
                    }
                }
                else
                {
                    _logger.LogInformation("Role '{Role}' already exists.", roleName);
                }
            }
        }

        private async Task<ApplicationUser> SeedMainUsersAsync(UserManager<ApplicationUser> userManager)
        {
            // Admin user
            var adminUser = await EnsureUserAsync(userManager, new ApplicationUser
            {
                UserName = "desktop",
                Email = "admin@skillpath.ba",
                FirstName = "Admin",
                LastName = "SkillPath",
                EmailConfirmed = true,
                IsActive = true,
                CityId = 2, // Sarajevo
                CreatedAt = DateTime.UtcNow
            }, "test", "Admin");

            // Student user
            await EnsureUserAsync(userManager, new ApplicationUser
            {
                UserName = "mobile",
                Email = "student@skillpath.ba",
                FirstName = "Student",
                LastName = "Korisnik",
                EmailConfirmed = true,
                IsActive = true,
                CityId = 1, // Mostar
                CreatedAt = DateTime.UtcNow
            }, "test", "Student");

            // Instructor user
            await EnsureUserAsync(userManager, new ApplicationUser
            {
                UserName = "instructor",
                Email = "instructor@skillpath.ba",
                FirstName = "Instruktor",
                LastName = "Predavac",
                EmailConfirmed = true,
                IsActive = true,
                CityId = 2, // Sarajevo
                CreatedAt = DateTime.UtcNow
            }, "test", "Instructor");

            return adminUser;
        }

        private async Task<ApplicationUser> EnsureUserAsync(
            UserManager<ApplicationUser> userManager,
            ApplicationUser user,
            string password,
            string role)
        {
            var existingUser = await userManager.FindByEmailAsync(user.Email!);
            if (existingUser != null)
            {
                _logger.LogInformation("User '{Email}' already exists.", user.Email);
                return existingUser;
            }

            var result = await userManager.CreateAsync(user, password);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, role);
                _logger.LogInformation("User '{Email}' created with role '{Role}'.", user.Email, role);
                return user;
            }

            _logger.LogError("Failed to create user '{Email}': {Errors}", user.Email,
                string.Join(", ", result.Errors.Select(e => e.Description)));
            return user;
        }

        private async Task SeedAdditionalDataAsync(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            ApplicationUser adminUser)
        {
            // Seed additional instructors
            var instructors = await SeedDataService.SeedInstructorsAsync(userManager, _logger);

            // Seed courses (check if already seeded)
            if (!await context.Courses.AnyAsync())
            {
                _logger.LogInformation("Seeding courses...");
                var allInstructors = new List<ApplicationUser>(instructors);

                // Add the main instructor
                var mainInstructor = await userManager.FindByEmailAsync("instructor@skillpath.ba");
                if (mainInstructor != null)
                {
                    allInstructors.Insert(0, mainInstructor);
                }

                var courses = SeedDataService.SeedCourses(allInstructors);
                context.Courses.AddRange(courses);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} courses.", courses.Count);

                // Seed schedules
                var schedules = SeedDataService.SeedSchedules(courses);
                context.CourseSchedules.AddRange(schedules);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} course schedules.", schedules.Count);

                // Seed students
                var students = await SeedDataService.SeedStudentsAsync(userManager, _logger);

                // Add main student
                var mainStudent = await userManager.FindByEmailAsync("student@skillpath.ba");
                if (mainStudent != null)
                {
                    students.Insert(0, mainStudent);
                }

                // Seed reservations
                var reservations = SeedDataService.SeedReservations(students, schedules);
                context.Reservations.AddRange(reservations);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} reservations.", reservations.Count);

                // Seed reviews
                var reviews = SeedDataService.SeedReviews(students, courses);
                context.Reviews.AddRange(reviews);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} reviews.", reviews.Count);

                // Seed favorites and views
                var (favorites, views) = SeedDataService.SeedFavoritesAndViews(students, courses);
                context.UserFavorites.AddRange(favorites);
                context.UserCourseViews.AddRange(views);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} favorites and {ViewCount} views.", favorites.Count, views.Count);

                // Seed notifications
                var notifications = SeedDataService.SeedNotifications(students, courses);
                context.Notifications.AddRange(notifications);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} notifications.", notifications.Count);

                // Seed broadcast notifications (admin dashboard)
                var broadcastNotifications = SeedDataService.SeedBroadcastNotifications();
                context.BroadcastNotifications.AddRange(broadcastNotifications);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} broadcast notifications.", broadcastNotifications.Count);

                // Seed news
                var news = SeedDataService.SeedNews(adminUser.Id);
                context.News.AddRange(news);
                await context.SaveChangesAsync();
                _logger.LogInformation("Seeded {Count} news items.", news.Count);
            }
            else
            {
                _logger.LogInformation("Seed data already exists, skipping.");
            }
        }
    }
}
