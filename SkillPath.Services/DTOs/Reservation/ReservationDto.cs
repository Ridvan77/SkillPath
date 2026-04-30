namespace SkillPath.Services.DTOs.Reservation
{
    public record ReservationDto(
        Guid Id,
        string ReservationCode,
        string UserId,
        string UserFullName,
        Guid CourseScheduleId,
        string CourseName,
        string? CourseImageUrl,
        string InstructorName,
        string ScheduleDay,
        string ScheduleTime,
        string Status,
        string FirstName,
        string LastName,
        string Email,
        string PhoneNumber,
        decimal TotalAmount,
        string? StripePaymentIntentId,
        DateTime CreatedAt,
        DateTime? CancelledAt,
        string? CancellationReason,
        decimal? RefundAmount,
        DateTime? RefundedAt
    );
}
