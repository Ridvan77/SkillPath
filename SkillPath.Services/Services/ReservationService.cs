using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Reservation;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Helpers;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class ReservationService : IReservationService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ReservationService> _logger;
        private readonly IPaymentService _paymentService;
        private readonly IRabbitMQPublisherService _rabbitMQPublisherService;
        private readonly INotificationService _notificationService;

        public ReservationService(
            ApplicationDbContext context,
            ILogger<ReservationService> logger,
            IPaymentService paymentService,
            IRabbitMQPublisherService rabbitMQPublisherService,
            INotificationService notificationService)
        {
            _context = context;
            _logger = logger;
            _paymentService = paymentService;
            _rabbitMQPublisherService = rabbitMQPublisherService;
            _notificationService = notificationService;
        }

        public async Task<PagedResult<ReservationDto>> GetAllAsync(int page, int pageSize, string? search, ReservationStatus? status)
        {
            var query = _context.Reservations
                .Include(r => r.User)
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                        .ThenInclude(c => c.Instructor)
                .AsQueryable();

            if (status.HasValue)
                query = query.Where(r => r.Status == status.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.ToLower();
                query = query.Where(r =>
                    r.ReservationCode.ToLower().Contains(s) ||
                    r.FirstName.ToLower().Contains(s) ||
                    r.LastName.ToLower().Contains(s) ||
                    r.Email.ToLower().Contains(s));
            }

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new ReservationDto(
                    r.Id,
                    r.ReservationCode,
                    r.UserId,
                    r.User.FirstName + " " + r.User.LastName,
                    r.CourseScheduleId,
                    r.CourseSchedule.Course.Title,
                    r.CourseSchedule.Course.ImageUrl,
                    r.CourseSchedule.Course.Instructor.FirstName + " " + r.CourseSchedule.Course.Instructor.LastName,
                    r.CourseSchedule.DayOfWeek.ToString(),
                    r.CourseSchedule.StartTime.ToString(@"hh\:mm") + " - " + r.CourseSchedule.EndTime.ToString(@"hh\:mm"),
                    r.Status.ToString(),
                    r.FirstName,
                    r.LastName,
                    r.Email,
                    r.PhoneNumber,
                    r.TotalAmount,
                    r.StripePaymentIntentId,
                    r.CreatedAt,
                    r.CancelledAt,
                    r.CancellationReason,
                    r.RefundAmount,
                    r.RefundedAt
                ))
                .ToListAsync();

            return new PagedResult<ReservationDto>(items, page, pageSize, totalCount);
        }

        public async Task<ReservationDto> GetByIdAsync(Guid id)
        {
            var reservation = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                        .ThenInclude(c => c.Instructor)
                .Where(r => r.Id == id)
                .Select(r => new ReservationDto(
                    r.Id,
                    r.ReservationCode,
                    r.UserId,
                    r.User.FirstName + " " + r.User.LastName,
                    r.CourseScheduleId,
                    r.CourseSchedule.Course.Title,
                    r.CourseSchedule.Course.ImageUrl,
                    r.CourseSchedule.Course.Instructor.FirstName + " " + r.CourseSchedule.Course.Instructor.LastName,
                    r.CourseSchedule.DayOfWeek.ToString(),
                    r.CourseSchedule.StartTime.ToString(@"hh\:mm") + " - " + r.CourseSchedule.EndTime.ToString(@"hh\:mm"),
                    r.Status.ToString(),
                    r.FirstName,
                    r.LastName,
                    r.Email,
                    r.PhoneNumber,
                    r.TotalAmount,
                    r.StripePaymentIntentId,
                    r.CreatedAt,
                    r.CancelledAt,
                    r.CancellationReason,
                    r.RefundAmount,
                    r.RefundedAt
                ))
                .FirstOrDefaultAsync();

            if (reservation == null)
                throw new NotFoundException($"Reservation with ID {id} not found.");

            return reservation;
        }

        public async Task<PagedResult<ReservationDto>> GetUserReservationsAsync(string userId, ReservationStatus? status, int page, int pageSize)
        {
            var query = _context.Reservations
                .Include(r => r.User)
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                        .ThenInclude(c => c.Instructor)
                .Where(r => r.UserId == userId)
                .AsQueryable();

            if (status.HasValue)
                query = query.Where(r => r.Status == status.Value);

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new ReservationDto(
                    r.Id,
                    r.ReservationCode,
                    r.UserId,
                    r.User.FirstName + " " + r.User.LastName,
                    r.CourseScheduleId,
                    r.CourseSchedule.Course.Title,
                    r.CourseSchedule.Course.ImageUrl,
                    r.CourseSchedule.Course.Instructor.FirstName + " " + r.CourseSchedule.Course.Instructor.LastName,
                    r.CourseSchedule.DayOfWeek.ToString(),
                    r.CourseSchedule.StartTime.ToString(@"hh\:mm") + " - " + r.CourseSchedule.EndTime.ToString(@"hh\:mm"),
                    r.Status.ToString(),
                    r.FirstName,
                    r.LastName,
                    r.Email,
                    r.PhoneNumber,
                    r.TotalAmount,
                    r.StripePaymentIntentId,
                    r.CreatedAt,
                    r.CancelledAt,
                    r.CancellationReason,
                    r.RefundAmount,
                    r.RefundedAt
                ))
                .ToListAsync();

            return new PagedResult<ReservationDto>(items, page, pageSize, totalCount);
        }

        public async Task<ReservationDto> CreateAsync(string userId, ReservationCreateRequest request)
        {
            var schedule = await _context.CourseSchedules
                .Include(cs => cs.Course)
                    .ThenInclude(c => c.Instructor)
                .FirstOrDefaultAsync(cs => cs.Id == request.CourseScheduleId);

            if (schedule == null)
                throw new NotFoundException($"CourseSchedule with ID {request.CourseScheduleId} not found.");

            if (!schedule.IsActive)
                throw new BusinessException("This schedule is no longer active.");

            if (schedule.CurrentEnrollment >= schedule.MaxCapacity)
                throw new BusinessException("This schedule is full. No more reservations can be made.");

            var hasDuplicate = await _context.Reservations.AnyAsync(r =>
                r.UserId == userId &&
                r.CourseScheduleId == request.CourseScheduleId &&
                (r.Status == ReservationStatus.Pending || r.Status == ReservationStatus.Active));

            if (hasDuplicate)
                throw new BusinessException("You already have an active or pending reservation for this schedule.");

            var reservation = new Reservation
            {
                Id = Guid.NewGuid(),
                ReservationCode = ReservationCodeGenerator.Generate(),
                UserId = userId,
                CourseScheduleId = request.CourseScheduleId,
                Status = ReservationStatus.Pending,
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                TotalAmount = schedule.Course.Price,
                CreatedAt = DateTime.UtcNow
            };

            _context.Reservations.Add(reservation);

            var statusHistory = new ReservationStatusHistory
            {
                Id = Guid.NewGuid(),
                ReservationId = reservation.Id,
                OldStatus = ReservationStatus.Pending,
                NewStatus = ReservationStatus.Pending,
                ChangedAt = DateTime.UtcNow,
                ChangedById = userId,
                Note = "Reservation created"
            };
            _context.ReservationStatusHistories.Add(statusHistory);

            await _context.SaveChangesAsync();

            _logger.LogInformation("Reservation {Code} created for user {UserId}, schedule {ScheduleId}",
                reservation.ReservationCode, userId, request.CourseScheduleId);

            // In-app notification
            try
            {
                await _notificationService.CreateSystemNotificationAsync(
                    userId,
                    $"Rezervacija kreirana - {schedule.Course.Title}",
                    $"Vasa rezervacija ({reservation.ReservationCode}) za kurs \"{schedule.Course.Title}\" je uspjesno kreirana. Iznos: {reservation.TotalAmount:F2} KM. Termin: {schedule.DayOfWeek} {schedule.StartTime}-{schedule.EndTime}.",
                    Model.Enums.NotificationType.Reservation,
                    reservation.Id.ToString(),
                    "Reservation");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to create notification for {Code}", reservation.ReservationCode);
            }

            // Email via RabbitMQ
            try
            {
                var emailBody = BuildReservationEmailHtml(
                    request.FirstName, request.LastName,
                    reservation.ReservationCode,
                    schedule.Course.Title,
                    $"{schedule.DayOfWeek} {schedule.StartTime}-{schedule.EndTime}",
                    $"{schedule.StartDate:dd.MM.yyyy} - {schedule.EndDate:dd.MM.yyyy}",
                    $"{schedule.Course.Instructor.FirstName} {schedule.Course.Instructor.LastName}",
                    request.Email,
                    request.PhoneNumber,
                    reservation.TotalAmount);

                await _rabbitMQPublisherService.PublishEmailAsync(new EmailMessage
                {
                    ToEmail = request.Email,
                    Subject = $"SkillPath - Potvrda rezervacije {reservation.ReservationCode}",
                    Body = emailBody
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish reservation email for {Code}", reservation.ReservationCode);
            }

            return await GetByIdAsync(reservation.Id);
        }

        public async Task<ReservationDto> ConfirmAsync(Guid id, string stripePaymentIntentId)
        {
            var reservation = await _context.Reservations
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                        .ThenInclude(c => c.Instructor)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reservation == null)
                throw new NotFoundException($"Reservation with ID {id} not found.");

            if (reservation.Status != ReservationStatus.Pending)
                throw new BusinessException($"Cannot confirm reservation with status '{reservation.Status}'. Only Pending reservations can be confirmed.");

            var oldStatus = reservation.Status;
            reservation.Status = ReservationStatus.Active;
            reservation.StripePaymentIntentId = stripePaymentIntentId;

            reservation.CourseSchedule.CurrentEnrollment++;

            var statusHistory = new ReservationStatusHistory
            {
                Id = Guid.NewGuid(),
                ReservationId = reservation.Id,
                OldStatus = oldStatus,
                NewStatus = ReservationStatus.Active,
                ChangedAt = DateTime.UtcNow,
                Note = "Payment confirmed"
            };
            _context.ReservationStatusHistories.Add(statusHistory);

            await _context.SaveChangesAsync();

            _logger.LogInformation("Reservation {Id} confirmed with PaymentIntent {PaymentIntentId}", id, stripePaymentIntentId);

            // Notification
            try
            {
                await _notificationService.CreateSystemNotificationAsync(
                    reservation.UserId,
                    $"Placanje potvrdjeno - {reservation.CourseSchedule.Course.Title}",
                    $"Vasa rezervacija ({reservation.ReservationCode}) za kurs \"{reservation.CourseSchedule.Course.Title}\" je uspjesno placena. Iznos: {reservation.TotalAmount:F2} KM.",
                    Model.Enums.NotificationType.Payment,
                    reservation.Id.ToString(),
                    "Reservation");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to create confirmation notification for {Id}", id);
            }

            // Email
            try
            {
                var s = reservation.CourseSchedule;
                var emailBody = BuildConfirmationEmailHtml(
                    reservation.FirstName, reservation.LastName,
                    reservation.ReservationCode,
                    s.Course.Title,
                    $"{s.DayOfWeek} {s.StartTime}-{s.EndTime}",
                    $"{s.StartDate:dd.MM.yyyy} - {s.EndDate:dd.MM.yyyy}",
                    $"{s.Course.Instructor.FirstName} {s.Course.Instructor.LastName}",
                    reservation.TotalAmount);

                await _rabbitMQPublisherService.PublishEmailAsync(new EmailMessage
                {
                    ToEmail = reservation.Email,
                    Subject = $"SkillPath - Placanje potvrdjeno {reservation.ReservationCode}",
                    Body = emailBody
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish confirmation email for {Id}", id);
            }

            return await GetByIdAsync(id);
        }

        public async Task<ReservationDto> CancelAsync(Guid id, string userId, string reason)
        {
            var reservation = await _context.Reservations
                .Include(r => r.CourseSchedule)
                    .ThenInclude(cs => cs.Course)
                        .ThenInclude(c => c.Instructor)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reservation == null)
                throw new NotFoundException($"Reservation with ID {id} not found.");

            if (reservation.Status != ReservationStatus.Active && reservation.Status != ReservationStatus.Pending)
                throw new BusinessException($"Cannot cancel reservation with status '{reservation.Status}'. Only Active or Pending reservations can be cancelled.");

            var oldStatus = reservation.Status;
            var wasActive = reservation.Status == ReservationStatus.Active;

            reservation.Status = ReservationStatus.Cancelled;
            reservation.CancelledAt = DateTime.UtcNow;
            reservation.CancellationReason = reason;

            if (wasActive)
            {
                reservation.CourseSchedule.CurrentEnrollment--;
            }

            var statusHistory = new ReservationStatusHistory
            {
                Id = Guid.NewGuid(),
                ReservationId = reservation.Id,
                OldStatus = oldStatus,
                NewStatus = ReservationStatus.Cancelled,
                ChangedAt = DateTime.UtcNow,
                ChangedById = userId,
                Note = $"Cancelled: {reason}"
            };
            _context.ReservationStatusHistories.Add(statusHistory);

            await _context.SaveChangesAsync();

            if (wasActive)
            {
                try
                {
                    await _paymentService.RefundPaymentAsync(id, reason);
                    _logger.LogInformation("Refund processed for reservation {Id}", id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to process refund for reservation {Id}", id);
                }
            }

            _logger.LogInformation("Reservation {Id} cancelled by user {UserId}. Reason: {Reason}", id, userId, reason);

            // Notification
            try
            {
                await _notificationService.CreateSystemNotificationAsync(
                    reservation.UserId,
                    $"Rezervacija otkazana - {reservation.CourseSchedule.Course.Title}",
                    $"Vasa rezervacija ({reservation.ReservationCode}) za kurs \"{reservation.CourseSchedule.Course.Title}\" je otkazana. Razlog: {reason}" +
                    (wasActive ? $"\nRefundacija u iznosu od {reservation.TotalAmount:F2} KM je pokrenuta." : ""),
                    Model.Enums.NotificationType.Reservation,
                    reservation.Id.ToString(),
                    "Reservation");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to create cancellation notification for {Id}", id);
            }

            // Email
            try
            {
                var s = reservation.CourseSchedule;
                var emailBody = BuildCancellationEmailHtml(
                    reservation.FirstName, reservation.LastName,
                    reservation.ReservationCode,
                    s.Course.Title,
                    $"{s.DayOfWeek} {s.StartTime}-{s.EndTime}",
                    reason,
                    reservation.TotalAmount,
                    wasActive);

                await _rabbitMQPublisherService.PublishEmailAsync(new EmailMessage
                {
                    ToEmail = reservation.Email,
                    Subject = $"SkillPath - Rezervacija otkazana {reservation.ReservationCode}",
                    Body = emailBody
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish cancellation email for {Id}", id);
            }

            return await GetByIdAsync(id);
        }

        private static string BuildReservationEmailHtml(
            string firstName, string lastName, string code,
            string courseName, string schedule, string period,
            string instructor, string email, string phone, decimal amount)
        {
            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">

  <!-- Header -->
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Potvrda rezervacije</p>
    </td>
  </tr>

  <!-- Success Badge -->
  <tr>
    <td style=""padding:32px 40px 0;text-align:center;"">
      <div style=""display:inline-block;background-color:#ecfdf5;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#10004;</div>
      <h2 style=""color:#059669;margin:16px 0 4px;font-size:20px;"">Rezervacija uspjesna!</h2>
      <p style=""color:#6b7280;margin:0;font-size:14px;"">Postovani {firstName} {lastName}, vasa rezervacija je kreirana.</p>
    </td>
  </tr>

  <!-- Reservation Code -->
  <tr>
    <td style=""padding:24px 40px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#e8eaf6;border:2px dashed #3F51B5;border-radius:10px;padding:20px;text-align:center;"">
        <tr><td>
          <p style=""color:#6b7280;margin:0 0 6px;font-size:12px;text-transform:uppercase;letter-spacing:1px;"">Broj potvrde</p>
          <p style=""color:#3F51B5;margin:0;font-size:28px;font-weight:800;letter-spacing:3px;"">{code}</p>
        </td></tr>
      </table>
    </td>
  </tr>

  <!-- Details Table -->
  <tr>
    <td style=""padding:0 40px 24px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;"">
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;width:140px;border-bottom:1px solid #e5e7eb;"">Kurs</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;font-weight:600;border-bottom:1px solid #e5e7eb;"">{courseName}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Termin</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{schedule}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Period</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{period}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Instruktor</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{instructor}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Polaznik</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{firstName} {lastName}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Email</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{email}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Telefon</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{phone}</td>
        </tr>
        <tr>
          <td style=""padding:14px 16px;color:#6b7280;font-size:13px;font-weight:700;"">Ukupan iznos</td>
          <td style=""padding:14px 16px;color:#3F51B5;font-size:18px;font-weight:800;"">{amount:F2} KM</td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- Footer -->
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>";
        }

        private static string BuildConfirmationEmailHtml(
            string firstName, string lastName, string code,
            string courseName, string schedule, string period,
            string instructor, decimal amount)
        {
            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Potvrda placanja</p>
    </td>
  </tr>
  <tr>
    <td style=""padding:32px 40px 0;text-align:center;"">
      <div style=""display:inline-block;background-color:#ecfdf5;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#128176;</div>
      <h2 style=""color:#059669;margin:16px 0 4px;font-size:20px;"">Placanje uspjesno!</h2>
      <p style=""color:#6b7280;margin:0;font-size:14px;"">Postovani {firstName} {lastName}, vase placanje je potvrdjeno.</p>
    </td>
  </tr>
  <tr>
    <td style=""padding:24px 40px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#e8eaf6;border:2px dashed #3F51B5;border-radius:10px;padding:20px;text-align:center;"">
        <tr><td>
          <p style=""color:#6b7280;margin:0 0 6px;font-size:12px;text-transform:uppercase;letter-spacing:1px;"">Broj potvrde</p>
          <p style=""color:#3F51B5;margin:0;font-size:28px;font-weight:800;letter-spacing:3px;"">{code}</p>
        </td></tr>
      </table>
    </td>
  </tr>
  <tr>
    <td style=""padding:0 40px 24px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;"">
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;width:140px;border-bottom:1px solid #e5e7eb;"">Kurs</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;font-weight:600;border-bottom:1px solid #e5e7eb;"">{courseName}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Termin</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{schedule}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Period</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{period}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Instruktor</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{instructor}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:14px 16px;color:#6b7280;font-size:13px;font-weight:700;"">Placeni iznos</td>
          <td style=""padding:14px 16px;color:#059669;font-size:18px;font-weight:800;"">{amount:F2} KM</td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td style=""padding:0 40px 24px;text-align:center;"">
      <p style=""color:#059669;background-color:#ecfdf5;padding:12px;border-radius:8px;font-size:14px;font-weight:600;margin:0;"">&#9989; Status: PLACENO - Vasa rezervacija je aktivna</p>
    </td>
  </tr>
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>";
        }

        private static string BuildCancellationEmailHtml(
            string firstName, string lastName, string code,
            string courseName, string schedule, string reason,
            decimal amount, bool wasActive)
        {
            var refundNote = wasActive
                ? $@"<tr>
    <td style=""padding:0 40px 24px;text-align:center;"">
      <p style=""color:#2563eb;background-color:#eff6ff;padding:12px;border-radius:8px;font-size:14px;font-weight:600;margin:0;"">&#128180; Refundacija u iznosu od {amount:F2} KM je pokrenuta i bit ce izvrsena u roku od 5-10 radnih dana.</p>
    </td>
  </tr>"
                : "";

            return $@"
<!DOCTYPE html>
<html>
<head><meta charset=""utf-8""></head>
<body style=""margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;"">
<table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#f4f4f7;padding:40px 0;"">
<tr><td align=""center"">
<table width=""600"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);"">
  <tr>
    <td style=""background:linear-gradient(135deg,#3F51B5,#303F9F);padding:32px 40px;text-align:center;"">
      <h1 style=""color:#ffffff;margin:0;font-size:24px;font-weight:700;"">SkillPath</h1>
      <p style=""color:rgba(255,255,255,0.85);margin:8px 0 0;font-size:14px;"">Otkazivanje rezervacije</p>
    </td>
  </tr>
  <tr>
    <td style=""padding:32px 40px 0;text-align:center;"">
      <div style=""display:inline-block;background-color:#fef2f2;border-radius:50%;width:64px;height:64px;line-height:64px;font-size:32px;"">&#10060;</div>
      <h2 style=""color:#dc2626;margin:16px 0 4px;font-size:20px;"">Rezervacija otkazana</h2>
      <p style=""color:#6b7280;margin:0;font-size:14px;"">Postovani {firstName} {lastName}, vasa rezervacija je otkazana.</p>
    </td>
  </tr>
  <tr>
    <td style=""padding:24px 40px;"">
      <table width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""border:1px solid #e5e7eb;border-radius:8px;overflow:hidden;"">
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;width:140px;border-bottom:1px solid #e5e7eb;"">Broj potvrde</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;font-weight:600;border-bottom:1px solid #e5e7eb;"">{code}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Kurs</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{courseName}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Termin</td>
          <td style=""padding:12px 16px;color:#111827;font-size:14px;border-bottom:1px solid #e5e7eb;"">{schedule}</td>
        </tr>
        <tr>
          <td style=""padding:12px 16px;color:#6b7280;font-size:13px;border-bottom:1px solid #e5e7eb;"">Razlog otkazivanja</td>
          <td style=""padding:12px 16px;color:#dc2626;font-size:14px;font-weight:500;border-bottom:1px solid #e5e7eb;"">{reason}</td>
        </tr>
        <tr style=""background-color:#f9fafb;"">
          <td style=""padding:14px 16px;color:#6b7280;font-size:13px;font-weight:700;"">Iznos</td>
          <td style=""padding:14px 16px;color:#111827;font-size:16px;font-weight:700;"">{amount:F2} KM</td>
        </tr>
      </table>
    </td>
  </tr>
  {refundNote}
  <tr>
    <td style=""background-color:#f9fafb;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;"">
      <p style=""color:#9ca3af;margin:0 0 4px;font-size:12px;"">Hvala sto koristite SkillPath!</p>
      <p style=""color:#9ca3af;margin:0;font-size:11px;"">Ovaj email je automatski generisan. Molimo ne odgovarajte na njega.</p>
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>";
        }
    }
}
