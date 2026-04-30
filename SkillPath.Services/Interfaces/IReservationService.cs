using SkillPath.Model.Enums;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.Reservation;

namespace SkillPath.Services.Interfaces;

public interface IReservationService
{
    Task<PagedResult<ReservationDto>> GetAllAsync(int page, int pageSize, string? search, ReservationStatus? status);
    Task<ReservationDto> GetByIdAsync(Guid id);
    Task<PagedResult<ReservationDto>> GetUserReservationsAsync(string userId, ReservationStatus? status, int page, int pageSize);
    Task<ReservationDto> CreateAsync(string userId, ReservationCreateRequest request);
    Task<ReservationDto> ConfirmAsync(Guid id, string stripePaymentIntentId);
    Task<ReservationDto> CancelAsync(Guid id, string userId, string reason);
}
