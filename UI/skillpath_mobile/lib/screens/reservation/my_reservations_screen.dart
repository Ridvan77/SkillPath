import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../providers/reservation_provider.dart';
import '../../widgets/reservation_status_chip.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().fetchUserReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCancelDialog(ReservationDto reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazi rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jeste li sigurni da zelite otkazati rezervaciju?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
                hintText: 'Opcionalno',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Da, otkazi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<ReservationProvider>().cancelReservation(
                reservation.id,
                reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : 'Korisnik otkazao',
              );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Rezervacija je uspjesno otkazana.'
                  : 'Greska prilikom otkazivanja.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Aktivne'),
                      if (provider.activeReservations.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildBadge(provider.activeReservations.length,
                            Colors.green),
                      ],
                    ],
                  ),
                );
              },
            ),
            Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Zavrsene'),
                      if (provider.completedReservations.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildBadge(
                            provider.completedReservations.length, Colors.blue),
                      ],
                    ],
                  ),
                );
              },
            ),
            Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Otkazane'),
                      if (provider.cancelledReservations.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildBadge(provider.cancelledReservations.length,
                            Colors.red),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReservationList(
                provider.activeReservations,
                showCancel: true,
                emptyMessage: 'Nemate aktivnih rezervacija.',
                emptyIcon: Icons.calendar_today_outlined,
              ),
              _buildReservationList(
                provider.completedReservations,
                emptyMessage: 'Nemate zavrsenih rezervacija.',
                emptyIcon: Icons.check_circle_outline,
              ),
              _buildReservationList(
                provider.cancelledReservations,
                showCancelInfo: true,
                emptyMessage: 'Nemate otkazanih rezervacija.',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildReservationList(
    List<ReservationDto> reservations, {
    bool showCancel = false,
    bool showCancelInfo = false,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ReservationProvider>().fetchUserReservations(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(
            reservation,
            showCancel: showCancel,
            showCancelInfo: showCancelInfo,
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(
    ReservationDto reservation, {
    bool showCancel = false,
    bool showCancelInfo = false,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.courseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ReservationStatusChip(status: reservation.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, reservation.instructorName),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.calendar_today,
                '${reservation.scheduleDay} | ${reservation.scheduleTime}'),
            const SizedBox(height: 6),
            _buildInfoRow(
                Icons.confirmation_number, reservation.reservationCode),
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.payment,
              NumberFormat.currency(locale: 'bs_BA', symbol: 'KM ')
                  .format(reservation.totalAmount),
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.access_time,
              dateFormat.format(reservation.createdAt),
            ),

            // Cancel Info
            if (showCancelInfo && reservation.cancelledAt != null) ...[
              const Divider(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otkazano: ${dateFormat.format(reservation.cancelledAt!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reservation.cancellationReason != null &&
                        reservation.cancellationReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Razlog: ${reservation.cancellationReason}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                    if (reservation.refundAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Refund: ${NumberFormat.currency(locale: 'bs_BA', symbol: 'KM ').format(reservation.refundAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Cancel Button
            if (showCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Otkazi'),
                  onPressed: () => _showCancelDialog(reservation),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
