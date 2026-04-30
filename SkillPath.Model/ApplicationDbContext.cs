using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SkillPath.Model.Entities;

namespace SkillPath.Model
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        // Main tables
        public DbSet<Course> Courses { get; set; }
        public DbSet<CourseSchedule> CourseSchedules { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<ReviewHelpfulVote> ReviewHelpfulVotes { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<News> News { get; set; }
        public DbSet<UserFavorite> UserFavorites { get; set; }
        public DbSet<UserCourseView> UserCourseViews { get; set; }
        public DbSet<ReservationStatusHistory> ReservationStatusHistories { get; set; }
        public DbSet<FcmToken> FcmTokens { get; set; }
        public DbSet<BroadcastNotification> BroadcastNotifications { get; set; }

        // Reference tables
        public DbSet<Category> Categories { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Country> Countries { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // ===== ApplicationUser =====
            builder.Entity<ApplicationUser>(entity =>
            {
                entity.Property(u => u.FirstName).IsRequired().HasMaxLength(50);
                entity.Property(u => u.LastName).IsRequired().HasMaxLength(50);
                entity.Property(u => u.ProfileImageUrl).HasMaxLength(500);
                entity.Property(u => u.IsActive).HasDefaultValue(true);

                entity.HasOne(u => u.City)
                    .WithMany(c => c.Users)
                    .HasForeignKey(u => u.CityId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // ===== Country (Reference) =====
            builder.Entity<Country>(entity =>
            {
                entity.Property(c => c.Name).IsRequired().HasMaxLength(100);
            });

            // ===== City (Reference) =====
            builder.Entity<City>(entity =>
            {
                entity.Property(c => c.Name).IsRequired().HasMaxLength(100);

                entity.HasOne(c => c.Country)
                    .WithMany(co => co.Cities)
                    .HasForeignKey(c => c.CountryId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ===== Category (Reference) =====
            builder.Entity<Category>(entity =>
            {
                entity.Property(c => c.Name).IsRequired().HasMaxLength(100);
                entity.Property(c => c.Description).HasMaxLength(500);
            });

            // ===== Course =====
            builder.Entity<Course>(entity =>
            {
                entity.HasKey(c => c.Id);
                entity.Property(c => c.Title).IsRequired().HasMaxLength(200);
                entity.Property(c => c.Description).IsRequired().HasMaxLength(2000);
                entity.Property(c => c.ShortDescription).IsRequired().HasMaxLength(300);
                entity.Property(c => c.Price).HasColumnType("decimal(18,2)");
                entity.Property(c => c.ImageUrl).HasMaxLength(500);
                entity.Property(c => c.IsActive).HasDefaultValue(true);
                entity.Property(c => c.InstructorId).IsRequired();

                entity.HasOne(c => c.Category)
                    .WithMany(cat => cat.Courses)
                    .HasForeignKey(c => c.CategoryId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(c => c.Instructor)
                    .WithMany(u => u.InstructorCourses)
                    .HasForeignKey(c => c.InstructorId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasIndex(c => c.CategoryId);
                entity.HasIndex(c => c.InstructorId);
                entity.HasIndex(c => c.IsActive);
            });

            // ===== CourseSchedule =====
            builder.Entity<CourseSchedule>(entity =>
            {
                entity.HasKey(cs => cs.Id);
                entity.Property(cs => cs.IsActive).HasDefaultValue(true);

                entity.HasOne(cs => cs.Course)
                    .WithMany(c => c.Schedules)
                    .HasForeignKey(cs => cs.CourseId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(cs => cs.CourseId);
            });

            // ===== Reservation =====
            builder.Entity<Reservation>(entity =>
            {
                entity.HasKey(r => r.Id);
                entity.Property(r => r.ReservationCode).IsRequired().HasMaxLength(20);
                entity.Property(r => r.FirstName).IsRequired().HasMaxLength(50);
                entity.Property(r => r.LastName).IsRequired().HasMaxLength(50);
                entity.Property(r => r.Email).IsRequired().HasMaxLength(100);
                entity.Property(r => r.PhoneNumber).IsRequired().HasMaxLength(20);
                entity.Property(r => r.TotalAmount).HasColumnType("decimal(18,2)");
                entity.Property(r => r.StripePaymentIntentId).HasMaxLength(100);
                entity.Property(r => r.CancellationReason).HasMaxLength(500);
                entity.Property(r => r.RefundAmount).HasColumnType("decimal(18,2)");
                entity.Property(r => r.UserId).IsRequired();

                entity.HasIndex(r => r.ReservationCode).IsUnique();
                entity.HasIndex(r => r.UserId);
                entity.HasIndex(r => r.Status);

                entity.HasOne(r => r.User)
                    .WithMany(u => u.Reservations)
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(r => r.CourseSchedule)
                    .WithMany(cs => cs.Reservations)
                    .HasForeignKey(r => r.CourseScheduleId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Soft delete global query filter
                entity.HasQueryFilter(r => !r.IsDeleted);
            });

            // ===== Payment =====
            builder.Entity<Payment>(entity =>
            {
                entity.HasKey(p => p.Id);
                entity.Property(p => p.Amount).HasColumnType("decimal(18,2)");
                entity.Property(p => p.Currency).IsRequired().HasMaxLength(3);
                entity.Property(p => p.PaymentMethod).HasMaxLength(50);
                entity.Property(p => p.StripePaymentIntentId).HasMaxLength(100);
                entity.Property(p => p.StripeChargeId).HasMaxLength(100);
                entity.Property(p => p.RefundAmount).HasColumnType("decimal(18,2)");
                entity.Property(p => p.RefundReason).HasMaxLength(500);

                entity.HasOne(p => p.Reservation)
                    .WithOne(r => r.Payment)
                    .HasForeignKey<Payment>(p => p.ReservationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // ===== Review =====
            builder.Entity<Review>(entity =>
            {
                entity.HasKey(r => r.Id);
                entity.Property(r => r.Comment).IsRequired().HasMaxLength(1000);
                entity.Property(r => r.Rating).IsRequired();
                entity.Property(r => r.IsVisible).HasDefaultValue(true);
                entity.Property(r => r.UserId).IsRequired();

                entity.HasOne(r => r.User)
                    .WithMany(u => u.Reviews)
                    .HasForeignKey(r => r.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(r => r.Course)
                    .WithMany(c => c.Reviews)
                    .HasForeignKey(r => r.CourseId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(r => new { r.UserId, r.CourseId }).IsUnique();
                entity.HasIndex(r => r.CourseId);
            });

            // ===== ReviewHelpfulVote =====
            builder.Entity<ReviewHelpfulVote>(entity =>
            {
                entity.HasKey(v => v.Id);

                entity.HasOne(v => v.Review)
                    .WithMany(r => r.HelpfulVotes)
                    .HasForeignKey(v => v.ReviewId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(v => v.User)
                    .WithMany(u => u.HelpfulVotes)
                    .HasForeignKey(v => v.UserId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasIndex(v => new { v.ReviewId, v.UserId }).IsUnique();
            });

            // ===== Notification =====
            builder.Entity<Notification>(entity =>
            {
                entity.HasKey(n => n.Id);
                entity.Property(n => n.Title).IsRequired().HasMaxLength(200);
                entity.Property(n => n.Content).IsRequired().HasMaxLength(2000);
                entity.Property(n => n.ImageUrl).HasMaxLength(500);
                entity.Property(n => n.RelatedEntityId).HasMaxLength(50);
                entity.Property(n => n.RelatedEntityType).HasMaxLength(50);

                entity.HasOne(n => n.User)
                    .WithMany(u => u.Notifications)
                    .HasForeignKey(n => n.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(n => n.UserId);
                entity.HasIndex(n => n.IsRead);
            });

            // ===== News =====
            builder.Entity<News>(entity =>
            {
                entity.HasKey(n => n.Id);
                entity.Property(n => n.Title).IsRequired().HasMaxLength(200);
                entity.Property(n => n.Content).IsRequired().HasMaxLength(5000);
                entity.Property(n => n.ImageUrl).HasMaxLength(500);
                entity.Property(n => n.CreatedById).IsRequired();

                entity.HasOne(n => n.CreatedBy)
                    .WithMany(u => u.CreatedNews)
                    .HasForeignKey(n => n.CreatedById)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // ===== UserFavorite =====
            builder.Entity<UserFavorite>(entity =>
            {
                entity.HasKey(f => f.Id);
                entity.Property(f => f.UserId).IsRequired();

                entity.HasOne(f => f.User)
                    .WithMany(u => u.Favorites)
                    .HasForeignKey(f => f.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(f => f.Course)
                    .WithMany(c => c.Favorites)
                    .HasForeignKey(f => f.CourseId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(f => new { f.UserId, f.CourseId }).IsUnique();
            });

            // ===== UserCourseView =====
            builder.Entity<UserCourseView>(entity =>
            {
                entity.HasKey(v => v.Id);
                entity.Property(v => v.UserId).IsRequired();

                entity.HasOne(v => v.User)
                    .WithMany(u => u.CourseViews)
                    .HasForeignKey(v => v.UserId)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasOne(v => v.Course)
                    .WithMany(c => c.Views)
                    .HasForeignKey(v => v.CourseId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(v => new { v.UserId, v.CourseId });
            });

            // ===== ReservationStatusHistory =====
            builder.Entity<ReservationStatusHistory>(entity =>
            {
                entity.HasKey(h => h.Id);
                entity.Property(h => h.Note).HasMaxLength(500);

                entity.HasOne(h => h.Reservation)
                    .WithMany(r => r.StatusHistory)
                    .HasForeignKey(h => h.ReservationId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(h => h.ChangedBy)
                    .WithMany()
                    .HasForeignKey(h => h.ChangedById)
                    .OnDelete(DeleteBehavior.NoAction);

                entity.HasIndex(h => h.ReservationId);
            });

            // ===== Seed Reference Data =====
            SeedReferenceData(builder);
        }

        private static void SeedReferenceData(ModelBuilder builder)
        {
            // Countries
            builder.Entity<Country>().HasData(
                new Country { Id = 1, Name = "Bosna i Hercegovina" },
                new Country { Id = 2, Name = "Hrvatska" },
                new Country { Id = 3, Name = "Srbija" }
            );

            // Cities
            builder.Entity<City>().HasData(
                new City { Id = 1, Name = "Mostar", CountryId = 1 },
                new City { Id = 2, Name = "Sarajevo", CountryId = 1 },
                new City { Id = 3, Name = "Tuzla", CountryId = 1 },
                new City { Id = 4, Name = "Zenica", CountryId = 1 },
                new City { Id = 5, Name = "Banja Luka", CountryId = 1 },
                new City { Id = 6, Name = "Zagreb", CountryId = 2 },
                new City { Id = 7, Name = "Split", CountryId = 2 },
                new City { Id = 8, Name = "Beograd", CountryId = 3 },
                new City { Id = 9, Name = "Novi Sad", CountryId = 3 }
            );

            // Categories
            builder.Entity<Category>().HasData(
                new Category { Id = 1, Name = "Programiranje", Description = "Kursevi programiranja i razvoja softvera" },
                new Category { Id = 2, Name = "Dizajn", Description = "Graficki dizajn, UI/UX i web dizajn" },
                new Category { Id = 3, Name = "Biznis", Description = "Menadzment, marketing i poduzetnistvo" },
                new Category { Id = 4, Name = "Jezici", Description = "Ucenje stranih jezika" },
                new Category { Id = 5, Name = "Muzika", Description = "Muzicka edukacija i instrumenti" },
                new Category { Id = 6, Name = "Fitness", Description = "Fitness treninzi i wellness" }
            );
        }
    }
}
