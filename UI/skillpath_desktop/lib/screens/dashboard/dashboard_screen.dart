import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/loading_widget.dart';
import '../course/course_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget(message: 'Ucitavanje statistike...');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dashboard', style: AppTheme.headingLarge),
                  OutlinedButton.icon(
                    onPressed: () => provider.fetchDashboardStats(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Osvjezi'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Error
              if (provider.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(provider.error!,
                      style: const TextStyle(color: AppTheme.error)),
                ),
                const SizedBox(height: 20),
              ],

              // Stat cards
              Row(
                children: [
                  _StatCard(
                    title: 'Ukupno kurseva',
                    value: provider.totalCourses.toString(),
                    icon: Icons.school_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 20),
                  _StatCard(
                    title: 'Aktivni studenti',
                    value: provider.activeStudents.toString(),
                    icon: Icons.people_rounded,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 20),
                  _StatCard(
                    title: 'Ukupan prihod',
                    value:
                        '${NumberFormat.currency(locale: 'bs', symbol: '', decimalDigits: 2).format(provider.totalRevenue)} KM',
                    icon: Icons.payments_rounded,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 20),
                  _StatCard(
                    title: 'Prosjecna ocjena',
                    value: provider.averageRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFF9800),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent reservations
              Container(
                width: double.infinity,
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nedavne rezervacije',
                            style: AppTheme.headingSmall,
                          ),
                          Text(
                            'Posljednjih ${provider.recentReservations.length}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (provider.recentReservations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Nema nedavnih rezervacija',
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                        columnSpacing: 24,
                        headingRowHeight: 48,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 56,
                        columns: const [
                          DataColumn(label: Text('Kod')),
                          DataColumn(label: Text('Korisnik')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Iznos')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Datum')),
                        ],
                        rows: provider.recentReservations.map((r) {
                          return DataRow(cells: [
                            DataCell(Text(
                              r.reservationCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            )),
                            DataCell(Text(r.fullName)),
                            DataCell(Text(r.email)),
                            DataCell(Text(
                              '${r.totalAmount.toStringAsFixed(2)} KM',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            )),
                            DataCell(_StatusChip(status: r.status)),
                            DataCell(Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(r.createdAt),
                              style: AppTheme.bodySmall,
                            )),
                          ]);
                        }).toList(),
                      ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick actions
              const Text('Brze akcije', style: AppTheme.headingSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickAction(
                    label: 'Novi kurs',
                    icon: Icons.add_circle_outline_rounded,
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CourseFormScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickAction(
                    label: 'Posalji obavjestenje',
                    icon: Icons.send_rounded,
                    color: AppTheme.info,
                    onTap: () => widget.onNavigate?.call(6), // Obavjestenja
                  ),
                  _QuickAction(
                    label: 'Generiraj izvjestaj',
                    icon: Icons.assessment_rounded,
                    color: AppTheme.success,
                    onTap: () => widget.onNavigate?.call(7), // Izvještaji
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                ],
              ),
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

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
