using Microsoft.AspNetCore.Identity;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;

namespace SkillPath.WebAPI.Services
{
    public static class SeedDataService
    {
        public static async Task<List<ApplicationUser>> SeedInstructorsAsync(
            UserManager<ApplicationUser> userManager,
            ILogger logger)
        {
            var instructors = new List<ApplicationUser>();

            var instructorData = new[]
            {
                ("instructor2", "instruktor2@skillpath.ba", "Amina", "Hadzic", 2),
                ("instructor3", "instruktor3@skillpath.ba", "Emir", "Begovic", 1),
                ("instructor4", "instruktor4@skillpath.ba", "Lejla", "Muratovic", 3),
            };

            foreach (var (username, email, firstName, lastName, cityId) in instructorData)
            {
                var existing = await userManager.FindByEmailAsync(email);
                if (existing != null)
                {
                    instructors.Add(existing);
                    logger.LogInformation("Instructor '{Email}' already exists.", email);
                    continue;
                }

                var user = new ApplicationUser
                {
                    UserName = username,
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    EmailConfirmed = true,
                    IsActive = true,
                    CityId = cityId,
                    CreatedAt = DateTime.UtcNow
                };

                var result = await userManager.CreateAsync(user, "test");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user, "Instructor");
                    instructors.Add(user);
                    logger.LogInformation("Instructor '{Email}' created.", email);
                }
                else
                {
                    logger.LogError("Failed to create instructor '{Email}': {Errors}", email,
                        string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }

            return instructors;
        }

        public static List<Course> SeedCourses(List<ApplicationUser> instructors)
        {
            var courses = new List<Course>
            {
                // Programiranje (CategoryId = 1)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "C# i .NET Razvoj",
                    ShortDescription = "Naucite C# programski jezik i .NET framework od osnova do naprednog nivoa.",
                    Description = "Sveobuhvatan kurs koji pokriva C# programski jezik, objektno-orijentirano programiranje, LINQ, Entity Framework, ASP.NET Core Web API i napredne koncepte poput async/await i dependency injection. Idealan za pocetnike koji zele postati backend developeri.",
                    Price = 450.00m,
                    DurationWeeks = 12,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=400&h=300&fit=crop",
                    CategoryId = 1,
                    InstructorId = instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-60)
                },
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Flutter Mobilni Razvoj",
                    ShortDescription = "Razvijajte cross-platform mobilne aplikacije koristeci Flutter i Dart.",
                    Description = "Kompletni kurs Flutter razvoja koji pokriva Dart programski jezik, Flutter widgete, state management sa Providerom, REST API integraciju, lokalno skladistenje podataka i deployment na Google Play i App Store. Kreirajte profesionalne mobilne aplikacije za Android i iOS.",
                    Price = 500.00m,
                    DurationWeeks = 10,
                    DifficultyLevel = DifficultyLevel.Intermediate,
                    ImageUrl = "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400&h=300&fit=crop",
                    CategoryId = 1,
                    InstructorId = instructors.Count > 1 ? instructors[1].Id : instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-45)
                },

                // Dizajn (CategoryId = 2)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "UI/UX Dizajn u Figmi",
                    ShortDescription = "Savladajte UI/UX dizajn koristeci Figma alat za profesionalne projekte.",
                    Description = "Prakticni kurs dizajna koji pokriva principe UI/UX dizajna, wireframing, prototipiranje, dizajn sisteme i kolaboraciju u timu. Naucite kreirati korisnicke interfejse koji su vizualno privlacni i funkcionalni. Radite na realnim projektima i izgradite portfolio.",
                    Price = 350.00m,
                    DurationWeeks = 8,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&h=300&fit=crop",
                    CategoryId = 2,
                    InstructorId = instructors.Count > 2 ? instructors[2].Id : instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-40)
                },
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Adobe Photoshop Masterclass",
                    ShortDescription = "Profesionalna obrada fotografija i kreiranje grafickog sadrzaja.",
                    Description = "Detaljni kurs Adobe Photoshopa koji pokriva alate za selekciju, layere, maske, retusiranje fotografija, kompoziting, tipografiju i pripremu za print i web. Pogodno za graficke dizajnere, fotografe i marketinske strucnjake.",
                    Price = 300.00m,
                    DurationWeeks = 6,
                    DifficultyLevel = DifficultyLevel.Intermediate,
                    ImageUrl = "https://images.unsplash.com/photo-1572044162444-ad60f128bdea?w=400&h=300&fit=crop",
                    CategoryId = 2,
                    InstructorId = instructors.Count > 2 ? instructors[2].Id : instructors[0].Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-35)
                },

                // Biznis (CategoryId = 3)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Digitalni Marketing",
                    ShortDescription = "Strategije digitalnog marketinga za rast vaseg biznisa.",
                    Description = "Kurs pokriva SEO optimizaciju, Google Ads, Facebook i Instagram oglasavanje, email marketing, content marketing, analitiku i mjerenje rezultata. Naucite kreirati i implementirati kompletnu digitalnu marketing strategiju za mali i srednji biznis.",
                    Price = 400.00m,
                    DurationWeeks = 8,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=300&fit=crop",
                    CategoryId = 3,
                    InstructorId = instructors.Count > 3 ? instructors[3].Id : instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-30)
                },
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Projektni Menadzment",
                    ShortDescription = "Upravljanje projektima koristeci agile i waterfall metodologije.",
                    Description = "Kurs projektnog menadzmenta koji pokriva tradicionalne i agile pristupe, Scrum framework, planiranje projekata, upravljanje rizicima, budzetiranje i komunikaciju sa stakeholderima. Priprema za PMP i Scrum Master certifikacije.",
                    Price = 380.00m,
                    DurationWeeks = 6,
                    DifficultyLevel = DifficultyLevel.Intermediate,
                    ImageUrl = "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop",
                    CategoryId = 3,
                    InstructorId = instructors.Count > 3 ? instructors[3].Id : instructors[0].Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-25)
                },

                // Jezici (CategoryId = 4)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Engleski Jezik - B2 Nivo",
                    ShortDescription = "Unaprijedite engleski jezik do B2 nivoa za poslovnu komunikaciju.",
                    Description = "Intenzivni kurs engleskog jezika fokusiran na postizanje B2 nivoa po CEFR standardu. Pokriva gramatiku, vokabular, konverzaciju, pismenu komunikaciju i poslovni engleski. Interaktivne vjezbe, grupne diskusije i individualni rad sa instruktorom.",
                    Price = 250.00m,
                    DurationWeeks = 16,
                    DifficultyLevel = DifficultyLevel.Intermediate,
                    ImageUrl = "https://images.unsplash.com/photo-1543109740-4bdb38fda756?w=400&h=300&fit=crop",
                    CategoryId = 4,
                    InstructorId = instructors.Count > 1 ? instructors[1].Id : instructors[0].Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-50)
                },
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Njemacki Jezik za Pocetnike",
                    ShortDescription = "Osnove njemackog jezika za svakodnevnu komunikaciju.",
                    Description = "Kurs njemackog jezika od nule do A2 nivoa. Pokriva osnovnu gramatiku, svakodnevni vokabular, izgovor, citanje i pisanje. Fokus na prakticnoj komunikaciji za zivot i rad u njemackogovornim zemljama. Priprema za Goethe-Zertifikat A2.",
                    Price = 280.00m,
                    DurationWeeks = 12,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1527866959252-deab85ef7d1b?w=400&h=300&fit=crop",
                    CategoryId = 4,
                    InstructorId = instructors.Count > 2 ? instructors[2].Id : instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-55)
                },

                // Muzika (CategoryId = 5)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Gitara za Pocetnike",
                    ShortDescription = "Naucite svirati akusticnu gitaru od prvih akorada.",
                    Description = "Kurs gitare za apsolutne pocetnike. Pokriva osnove sviranja, citanje tabulatura, osnovne akorde, ritam i picking tehnike. Na kraju kursa moci cete svirati popularne pjesme i razumjeti muzicku teoriju potrebnu za dalji napredak.",
                    Price = 200.00m,
                    DurationWeeks = 8,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=400&h=300&fit=crop",
                    CategoryId = 5,
                    InstructorId = instructors.Count > 3 ? instructors[3].Id : instructors[0].Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                },
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Produkcija Muzike u Abletonu",
                    ShortDescription = "Kreiranje elektronske muzike koristeci Ableton Live.",
                    Description = "Napredni kurs muzicke produkcije u Ableton Live-u. Pokriva snimanje, MIDI programiranje, sinteze zvuka, miksanje, mastering i pripremu za distribuciju. Idealan za DJ-eve i producente koji zele unaprijediti svoje vjestine.",
                    Price = 450.00m,
                    DurationWeeks = 10,
                    DifficultyLevel = DifficultyLevel.Advanced,
                    ImageUrl = "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=300&fit=crop",
                    CategoryId = 5,
                    InstructorId = instructors.Count > 1 ? instructors[1].Id : instructors[0].Id,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },

                // Fitness (CategoryId = 6)
                new Course
                {
                    Id = Guid.NewGuid(),
                    Title = "Funkcionalni Fitness Trening",
                    ShortDescription = "Poboljsajte kondiciju i snagu kroz funkcionalne vjezbe.",
                    Description = "Program funkcionalnog fitness treninga koji kombinuje vjezbe snage, izdrzljivosti, fleksibilnosti i koordinacije. Prilagodjen za sve nivoe, sa individualnim pristupom i pravilnom formom izvodjenja vjezbi. Ukljucuje plan ishrane i suplementacije.",
                    Price = 180.00m,
                    DurationWeeks = 8,
                    DifficultyLevel = DifficultyLevel.Beginner,
                    ImageUrl = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop",
                    CategoryId = 6,
                    InstructorId = instructors.Count > 3 ? instructors[3].Id : instructors[0].Id,
                    IsFeatured = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
            };

            return courses;
        }

        public static List<CourseSchedule> SeedSchedules(List<Course> courses)
        {
            var schedules = new List<CourseSchedule>();
            var baseDate = DateTime.UtcNow.Date;

            foreach (var course in courses)
            {
                // Schedule 1: Morning weekday
                schedules.Add(new CourseSchedule
                {
                    Id = Guid.NewGuid(),
                    CourseId = course.Id,
                    DayOfWeek = DayOfWeek.Monday,
                    StartTime = new TimeSpan(9, 0, 0),
                    EndTime = new TimeSpan(11, 0, 0),
                    StartDate = baseDate.AddDays(7),
                    EndDate = baseDate.AddDays(7 + course.DurationWeeks * 7),
                    MaxCapacity = 20,
                    CurrentEnrollment = 0,
                    IsActive = true
                });

                // Schedule 2: Evening weekday
                schedules.Add(new CourseSchedule
                {
                    Id = Guid.NewGuid(),
                    CourseId = course.Id,
                    DayOfWeek = DayOfWeek.Wednesday,
                    StartTime = new TimeSpan(18, 0, 0),
                    EndTime = new TimeSpan(20, 0, 0),
                    StartDate = baseDate.AddDays(7),
                    EndDate = baseDate.AddDays(7 + course.DurationWeeks * 7),
                    MaxCapacity = 15,
                    CurrentEnrollment = 0,
                    IsActive = true
                });

                // Schedule 3: Weekend (for some courses)
                if (courses.IndexOf(course) % 2 == 0)
                {
                    schedules.Add(new CourseSchedule
                    {
                        Id = Guid.NewGuid(),
                        CourseId = course.Id,
                        DayOfWeek = DayOfWeek.Saturday,
                        StartTime = new TimeSpan(10, 0, 0),
                        EndTime = new TimeSpan(13, 0, 0),
                        StartDate = baseDate.AddDays(7),
                        EndDate = baseDate.AddDays(7 + course.DurationWeeks * 7),
                        MaxCapacity = 25,
                        CurrentEnrollment = 0,
                        IsActive = true
                    });
                }
            }

            return schedules;
        }

        public static async Task<List<ApplicationUser>> SeedStudentsAsync(
            UserManager<ApplicationUser> userManager,
            ILogger logger)
        {
            var students = new List<ApplicationUser>();

            var studentData = new[]
            {
                ("student2", "student2@skillpath.ba", "Haris", "Begovic", 2),
                ("student3", "student3@skillpath.ba", "Amra", "Delic", 1),
                ("student4", "student4@skillpath.ba", "Tarik", "Kovacevic", 3),
                ("student5", "student5@skillpath.ba", "Merima", "Hrustanovic", 4),
                ("student6", "student6@skillpath.ba", "Adnan", "Salkic", 5),
                ("student7", "student7@skillpath.ba", "Selma", "Imamovic", 2),
                ("student8", "student8@skillpath.ba", "Kenan", "Causevic", 1),
                ("student9", "student9@skillpath.ba", "Lamija", "Hodzic", 3),
                ("student10", "student10@skillpath.ba", "Nedim", "Muminovic", 2),
                ("student11", "student11@skillpath.ba", "Lejla", "Spahic", 4),
            };

            foreach (var (username, email, firstName, lastName, cityId) in studentData)
            {
                var existing = await userManager.FindByEmailAsync(email);
                if (existing != null)
                {
                    students.Add(existing);
                    logger.LogInformation("Student '{Email}' already exists.", email);
                    continue;
                }

                var user = new ApplicationUser
                {
                    UserName = username,
                    Email = email,
                    FirstName = firstName,
                    LastName = lastName,
                    EmailConfirmed = true,
                    IsActive = true,
                    CityId = cityId,
                    CreatedAt = DateTime.UtcNow
                };

                var result = await userManager.CreateAsync(user, "test");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user, "Student");
                    students.Add(user);
                    logger.LogInformation("Student '{Email}' created.", email);
                }
                else
                {
                    logger.LogError("Failed to create student '{Email}': {Errors}", email,
                        string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }

            return students;
        }

        public static List<Reservation> SeedReservations(
            List<ApplicationUser> students,
            List<CourseSchedule> schedules)
        {
            var reservations = new List<Reservation>();
            var random = new Random(42); // Deterministic seed
            var statuses = new[] { ReservationStatus.Active, ReservationStatus.Pending, ReservationStatus.Completed, ReservationStatus.Cancelled };

            for (int i = 0; i < 20 && i < students.Count * schedules.Count; i++)
            {
                var student = students[i % students.Count];
                var schedule = schedules[i % schedules.Count];
                var status = statuses[i % statuses.Length];

                reservations.Add(new Reservation
                {
                    Id = Guid.NewGuid(),
                    ReservationCode = $"SP-{2024}{(i + 1):D4}",
                    UserId = student.Id,
                    CourseScheduleId = schedule.Id,
                    Status = status,
                    FirstName = student.FirstName,
                    LastName = student.LastName,
                    Email = student.Email!,
                    PhoneNumber = $"+387-6{random.Next(0, 9)}-{random.Next(100, 999)}-{random.Next(100, 999)}",
                    TotalAmount = 100m + (i * 25m),
                    CreatedAt = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                    CancelledAt = status == ReservationStatus.Cancelled ? DateTime.UtcNow.AddDays(-random.Next(1, 5)) : null,
                    CancellationReason = status == ReservationStatus.Cancelled ? "Sprijecen/a sam prisustvovati." : null,
                    IsDeleted = false
                });
            }

            return reservations;
        }

        public static List<Review> SeedReviews(
            List<ApplicationUser> students,
            List<Course> courses)
        {
            var reviews = new List<Review>();
            var comments = new[]
            {
                "Odlican kurs! Instruktor objasnjava na razumljiv nacin.",
                "Mnogo sam naucio/la, preporucujem svima.",
                "Dobar sadrzaj, ali moglo bi biti vise prakticnih primjera.",
                "Fantasticno iskustvo, vratio/la bih se opet.",
                "Solidno za pocetnike, ali naprednim korisnicima moze biti sporo.",
                "Najbolji kurs koji sam pohadjao/la do sada!",
                "Instruktor je veoma strpljiv i profesionalan.",
                "Cijena je povoljna za kvalitetu koju dobijete.",
                "Materijali su odlicni i dobro organizovani.",
                "Moglo bi biti vise interakcije sa drugim polaznicima.",
                "Savrseno za ljude koji zele promijeniti karijeru.",
                "Prakticni projekti su me pripremili za posao.",
                "Preporucujem ovaj kurs svima koji zele nauciti nesto novo.",
                "Dinamicna nastava sa puno primjera iz prakse.",
                "Odlican omjer cijene i kvalitete."
            };

            var usedPairs = new HashSet<string>();

            for (int i = 0; i < 15 && i < students.Count * courses.Count; i++)
            {
                var studentIndex = i % students.Count;
                var courseIndex = i % courses.Count;

                // Ensure unique (userId, courseId) pairs
                var pairKey = $"{students[studentIndex].Id}_{courses[courseIndex].Id}";
                if (usedPairs.Contains(pairKey))
                {
                    courseIndex = (courseIndex + 1) % courses.Count;
                    pairKey = $"{students[studentIndex].Id}_{courses[courseIndex].Id}";
                    if (usedPairs.Contains(pairKey)) continue;
                }
                usedPairs.Add(pairKey);

                reviews.Add(new Review
                {
                    Id = Guid.NewGuid(),
                    UserId = students[studentIndex].Id,
                    CourseId = courses[courseIndex].Id,
                    Rating = 3 + (i % 3), // Ratings between 3-5
                    Comment = comments[i % comments.Length],
                    CreatedAt = DateTime.UtcNow.AddDays(-i * 2),
                    IsVisible = true,
                    IsReported = false,
                    ReportCount = 0,
                    HelpfulCount = i % 5
                });
            }

            return reviews;
        }

        public static (List<UserFavorite> Favorites, List<UserCourseView> Views) SeedFavoritesAndViews(
            List<ApplicationUser> students,
            List<Course> courses)
        {
            var favorites = new List<UserFavorite>();
            var views = new List<UserCourseView>();
            var usedFavPairs = new HashSet<string>();

            // 20 favorites
            for (int i = 0; i < 20 && i < students.Count * courses.Count; i++)
            {
                var studentIndex = i % students.Count;
                var courseIndex = i % courses.Count;
                var pairKey = $"{students[studentIndex].Id}_{courses[courseIndex].Id}";

                if (usedFavPairs.Contains(pairKey))
                {
                    courseIndex = (courseIndex + 1) % courses.Count;
                    pairKey = $"{students[studentIndex].Id}_{courses[courseIndex].Id}";
                    if (usedFavPairs.Contains(pairKey)) continue;
                }
                usedFavPairs.Add(pairKey);

                favorites.Add(new UserFavorite
                {
                    Id = Guid.NewGuid(),
                    UserId = students[studentIndex].Id,
                    CourseId = courses[courseIndex].Id,
                    CreatedAt = DateTime.UtcNow.AddDays(-i)
                });
            }

            // 50 views (can have duplicates for same user/course)
            for (int i = 0; i < 50; i++)
            {
                var studentIndex = i % students.Count;
                var courseIndex = i % courses.Count;

                views.Add(new UserCourseView
                {
                    Id = Guid.NewGuid(),
                    UserId = students[studentIndex].Id,
                    CourseId = courses[courseIndex].Id,
                    ViewedAt = DateTime.UtcNow.AddDays(-i).AddHours(-(i % 12))
                });
            }

            return (favorites, views);
        }

        public static List<Notification> SeedNotifications(
            List<ApplicationUser> students,
            List<Course> courses)
        {
            var notifications = new List<Notification>();

            var notificationTemplates = new[]
            {
                (NotificationType.System, "Dobrodosli na SkillPath!", "Hvala sto ste se registrovali. Istrazite nase kurseve i zapocnite ucenje vec danas."),
                (NotificationType.Course, "Novi kurs dostupan!", "Pogledajte nase najnovije kurseve i pronadite nesto za sebe."),
                (NotificationType.Reservation, "Rezervacija potvrdjenja", "Vasa rezervacija je uspjesno potvrdjenja. Vidimo se na kursu!"),
                (NotificationType.Payment, "Uplata primljena", "Vasa uplata je uspjesno obradjena. Hvala vam na povjerenju."),
                (NotificationType.Promotion, "Specijalna ponuda!", "Iskoristite 20% popusta na sve kurseve ovog mjeseca."),
                (NotificationType.System, "Azuriranje profila", "Molimo vas da azurirate svoj profil za bolje iskustvo koristenja platforme."),
                (NotificationType.Course, "Podsjetnik za kurs", "Vas kurs pocinje sutra. Ne zaboravite se pripremiti!"),
                (NotificationType.Promotion, "Preporuceni kursevi", "Na osnovu vasih interesovanja, preporucujemo vam nove kurseve."),
            };

            for (int i = 0; i < notificationTemplates.Length && i < students.Count; i++)
            {
                var (type, title, content) = notificationTemplates[i];
                notifications.Add(new Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = students[i % students.Count].Id,
                    Title = title,
                    Content = content,
                    Type = type,
                    IsRead = i % 3 == 0,
                    CreatedAt = DateTime.UtcNow.AddDays(-i * 3),
                    RelatedEntityId = courses.Count > 0 ? courses[i % courses.Count].Id.ToString() : null,
                    RelatedEntityType = type == NotificationType.Course ? "Course" :
                                       type == NotificationType.Reservation ? "Reservation" : null
                });
            }

            return notifications;
        }

        public static List<BroadcastNotification> SeedBroadcastNotifications()
        {
            return new List<BroadcastNotification>
            {
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "Novi Programiranje Kursevi Dostupni",
                    Content = "Dodali smo 3 nova kursa iz oblasti programiranja. Pogledajte ponudu i rezervišite svoje mjesto!",
                    Type = NotificationType.Course,
                    TargetGroup = "students",
                    Status = BroadcastStatus.Sent,
                    SentAt = DateTime.UtcNow.AddDays(-5),
                    RecipientCount = 12,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "20% Popust na Dizajn Kurseve",
                    Content = "Ograničena ponuda! Iskoristite 20% popust na sve kurseve iz kategorije Dizajn. Važi do kraja sedmice.",
                    Type = NotificationType.Promotion,
                    TargetGroup = "all",
                    Status = BroadcastStatus.Sent,
                    SentAt = DateTime.UtcNow.AddDays(-3),
                    RecipientCount = 16,
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                },
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "Planirano Održavanje Sistema",
                    Content = "Sistem će biti nedostupan u nedjelju od 02:00 do 04:00 zbog planiranog održavanja.",
                    Type = NotificationType.System,
                    TargetGroup = "all",
                    Status = BroadcastStatus.Scheduled,
                    ScheduledAt = DateTime.UtcNow.AddDays(3),
                    RecipientCount = 0,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "Poziv za Nove Predavače",
                    Content = "Tražimo iskusne predavače za proširenje naše ponude kurseva. Prijavite se danas!",
                    Type = NotificationType.System,
                    TargetGroup = "instructors",
                    Status = BroadcastStatus.Sent,
                    SentAt = DateTime.UtcNow.AddDays(-7),
                    RecipientCount = 4,
                    CreatedAt = DateTime.UtcNow.AddDays(-7)
                },
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "Ljetni Popusti na Sve Kurseve",
                    Content = "Specijalna ljetna ponuda - 30% popusta na sve kurseve. Ponuda traje do kraja mjeseca!",
                    Type = NotificationType.Promotion,
                    TargetGroup = "all",
                    Status = BroadcastStatus.Scheduled,
                    ScheduledAt = DateTime.UtcNow.AddDays(7),
                    RecipientCount = 0,
                    CreatedAt = DateTime.UtcNow
                },
                new BroadcastNotification
                {
                    Id = Guid.NewGuid(),
                    Title = "Novi Termin za Flutter Kurs",
                    Content = "Dodan je novi termin za Flutter Mobilni Razvoj kurs. Rezervišite mjesto dok je dostupno!",
                    Type = NotificationType.Course,
                    TargetGroup = "students",
                    Status = BroadcastStatus.Sent,
                    SentAt = DateTime.UtcNow.AddDays(-2),
                    RecipientCount = 12,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
            };
        }

        public static List<News> SeedNews(string adminUserId)
        {
            return new List<News>
            {
                new News
                {
                    Id = Guid.NewGuid(),
                    Title = "SkillPath platforma je lansirana!",
                    Content = "Sa zadovoljstvom najavljujemo lansiranje SkillPath platforme za online edukaciju. Nasa misija je pruziti kvalitetne kurseve iz razlicitih oblasti, od programiranja i dizajna do jezika i fitnessa. Registrujte se danas i zapocnite svoje putovanje ucenja!",
                    CreatedAt = DateTime.UtcNow.AddDays(-30),
                    CreatedById = adminUserId
                },
                new News
                {
                    Id = Guid.NewGuid(),
                    Title = "Novi kursevi za proljece 2024",
                    Content = "Dodali smo 5 novih kurseva u nasu ponudu! Posebno preporucujemo kurseve Flutter mobilnog razvoja i UI/UX dizajna u Figmi. Svi novi kursevi imaju specijalni popust od 15% za rane prijave. Ne propustite priliku da unaprijedite svoje vjestine.",
                    CreatedAt = DateTime.UtcNow.AddDays(-15),
                    CreatedById = adminUserId
                },
                new News
                {
                    Id = Guid.NewGuid(),
                    Title = "Program za stipendije - prijavite se!",
                    Content = "SkillPath pokrece program stipendija za talentovane studente koji nemaju finansijske mogucnosti za placanje kurseva. Prijavite se do kraja mjeseca i mozete dobiti potpunu stipendiju za jedan od nasih kurseva. Vise informacija na nasoj web stranici.",
                    CreatedAt = DateTime.UtcNow.AddDays(-5),
                    CreatedById = adminUserId
                }
            };
        }
    }
}
