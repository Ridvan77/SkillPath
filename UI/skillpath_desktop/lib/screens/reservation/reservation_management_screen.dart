import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/reservation_management_provider.dart';
import '../../widgets/loading_widget.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReservationManagementProvider>()
          .fetchReservations(page: 1);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<ReservationManagementProvider>().fetchReservations(
          page: 1,
          search: _searchController.text.trim(),
        );
  }

  Future<void> _confirmReservation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrdi rezervaciju'),
        content: const Text(
            'Da li ste sigurni da želite potvrditi ovu rezervaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<ReservationManagementProvider>()
          .confirmReservation(id, '');
    }
  }

  Future<void> _cancelReservation(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Otkazivanje rezervacije'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unesite razlog otkazivanja:'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Razlog...',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Razlog je obavezan'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Nazad'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Otkaži rezervaciju'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty && mounted) {
      final success = await context
          .read<ReservationManagementProvider>()
          .cancelReservation(id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Rezervacija uspješno otkazana'
                : 'Greška pri otkazivanju rezervacije'),
          ),
        );
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservationManagementProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upravljanje rezervacijama',
                  style: AppTheme.headingLarge),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                    label: 'Ukupno',
                    value: provider.totalReservations.toString(),
                    color: AppTheme.primary,
                    icon: Icons.event_note_rounded,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    label: 'Aktivne',
                    value: provider.activeCount.toString(),
                    color: AppTheme.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    label: 'Zavrsene',
                    value: provider.completedCount.toString(),
                    color: AppTheme.info,
                    icon: Icons.done_all_rounded,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    label: 'Otkazane',
                    value: provider.cancelledCount.toString(),
                    color: AppTheme.error,
                    icon: Icons.cancel_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search + filter
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Pretrazi po kodu, imenu, emailu...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: provider.statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Svi')),
                        DropdownMenuItem(
                            value: '0', child: Text('Na cekanju')),
                        DropdownMenuItem(
                            value: '1', child: Text('Potvrdjene')),
                        DropdownMenuItem(
                            value: '2', child: Text('Zavrsene')),
                        DropdownMenuItem(
                            value: '3', child: Text('Otkazane')),
                      ],
                      onChanged: (v) => provider.fetchReservations(
                          page: 1, status: v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onSearch,
                    child: const Text('Pretrazi'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Table
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: AppTheme.cardDecoration,
                  child: provider.isLoading
                      ? const LoadingWidget()
                      : provider.reservations.isEmpty
                          ? const Center(
                              child: Text('Nema rezervacija za prikaz',
                                  style: AppTheme.bodySmall))
                          : Column(
                              children: [
                                Expanded(
                                  child: DataTable2(
                                    columnSpacing: 12,
                                    horizontalMargin: 16,
                                    minWidth: 1000,
                                    headingRowHeight: 52,
                                    dataRowHeight: 56,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    columns: const [
                                      DataColumn2(
                                          label: Text('Kod'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Korisnik'),
                                          size: ColumnSize.M),
                                      DataColumn2(
                                          label: Text('Kurs'),
                                          size: ColumnSize.M),
                                      DataColumn2(
                                          label: Text('Instruktor'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Datum'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Iznos'),
                                          size: ColumnSize.S,
                                          numeric: true),
                                      DataColumn2(
                                          label: Text('Status'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Akcije'),
                                          fixedWidth: 110),
                                    ],
                                    rows: provider.reservations.map((r) {
                                      return DataRow2(cells: [
                                        DataCell(Text(r.reservationCode,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 13))),
                                        DataCell(Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(r.fullName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text(r.email,
                                                style: AppTheme.bodySmall),
                                          ],
                                        )),
                                        DataCell(Text(r.courseName,
                                            overflow:
                                                TextOverflow.ellipsis)),
                                        DataCell(Text(r.instructorName)),
                                        DataCell(Text(
                                          DateFormat('dd.MM.yyyy')
                                              .format(r.createdAt),
                                          style: AppTheme.bodySmall,
                                        )),
                                        DataCell(Text(
                                          '${r.totalAmount.toStringAsFixed(2)} KM',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        )),
                                        DataCell(
                                            _StatusChip(status: r.status)),
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (r.status == 'Pending')
                                              IconButton(
                                                icon: Icon(
                                                    Icons
                                                        .check_circle_rounded,
                                                    size: 18,
                                                    color:
                                                        AppTheme.success),
                                                tooltip: 'Potvrdi',
                                                onPressed: () =>
                                                    _confirmReservation(
                                                        r.id),
                                              ),
                                            if (r.status != 'Cancelled' &&
                                                r.status != 'Completed')
                                              IconButton(
                                                icon: Icon(
                                                    Icons.cancel_rounded,
                                                    size: 18,
                                                    color: AppTheme.error),
                                                tooltip: 'Otkazi',
                                                onPressed: () =>
                                                    _cancelReservation(
                                                        r.id),
                                              ),
                                          ],
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                                if (provider.totalPages > 1)
                                  _buildPagination(provider),
                              ],
                            ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination(ReservationManagementProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: provider.currentPage > 1
                ? () => provider.fetchReservations(
                    page: provider.currentPage - 1)
                : null,
          ),
          Text(
              'Stranica ${provider.currentPage} od ${provider.totalPages}',
              style: AppTheme.bodySmall),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: provider.currentPage < provider.totalPages
                ? () => provider.fetchReservations(
                    page: provider.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label, style: AppTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  static const _statusLabels = {
    'Pending': 'Na čekanju',
    'Confirmed': 'Potvrđena',
    'Active': 'Aktivna',
    'Completed': 'Završena',
    'Cancelled': 'Otkazana',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = _statusLabels[status] ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
