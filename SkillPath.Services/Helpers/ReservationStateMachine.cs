using SkillPath.Model.Enums;
using SkillPath.Services.Exceptions;

namespace SkillPath.Services.Helpers
{
    public static class ReservationStateMachine
    {
        private static readonly Dictionary<ReservationStatus, HashSet<ReservationStatus>> AllowedTransitions = new()
        {
            { ReservationStatus.Pending, new HashSet<ReservationStatus> { ReservationStatus.Active, ReservationStatus.Cancelled } },
            { ReservationStatus.Active, new HashSet<ReservationStatus> { ReservationStatus.Completed, ReservationStatus.CancellationPendingRefund, ReservationStatus.Cancelled } },
            { ReservationStatus.CancellationPendingRefund, new HashSet<ReservationStatus> { ReservationStatus.Cancelled, ReservationStatus.RefundFailed } },
            // Terminal states — no outgoing transitions allowed
            { ReservationStatus.Completed, new HashSet<ReservationStatus>() },
            { ReservationStatus.Cancelled, new HashSet<ReservationStatus>() },
            { ReservationStatus.RefundFailed, new HashSet<ReservationStatus>() },
        };

        public static void ValidateTransition(ReservationStatus from, ReservationStatus to)
        {
            if (AllowedTransitions.TryGetValue(from, out var allowed) && allowed.Contains(to))
                return;

            throw new BusinessException($"Prelaz statusa rezervacije iz '{from}' u '{to}' nije dozvoljen.");
        }
    }
}
