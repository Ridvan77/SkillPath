import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../main.dart';
import '../../providers/notification_provider.dart';

class ReservationStep3ConfirmationScreen extends StatefulWidget {
  final ReservationDto reservation;
  final CourseDetailDto course;
  final CourseScheduleDto schedule;

  const ReservationStep3ConfirmationScreen({
    super.key,
    required this.reservation,
    required this.course,
    required this.schedule,
  });

  @override
  State<ReservationStep3ConfirmationScreen> createState() =>
      _ReservationStep3ConfirmationScreenState();
}

class _ReservationStep3ConfirmationScreenState
    extends State<ReservationStep3ConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications so the new reservation notification appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  String _formatPrice(double price) {
    return '${NumberFormat("#,##0.00", "bs_BA").format(price)} KM';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final c = widget.course;
    final s = widget.schedule;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Success Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Rezervacija uspjesna!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vasa rezervacija je potvrdjena. Notifikacija i e-mail\nsa detaljima su vam poslani.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),

                // Reservation Code (prominent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5FC7).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF5B5FC7).withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Broj potvrde',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.reservationCode,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B5FC7),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _row('Datum kreiranja', DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt)),
                      _divider(),
                      _row('Naziv kursa', c.title),
                      _divider(),
                      _row('Termin', '${s.dayOfWeek} | ${s.startTime} - ${s.endTime}'),
                      _divider(),
                      _row('Period', '${DateFormat('dd.MM.yyyy').format(s.startDate)} - ${DateFormat('dd.MM.yyyy').format(s.endDate)}'),
                      _divider(),
                      _row('Instruktor', c.instructorName),
                      _divider(),
                      _row('Ime i prezime', '${r.firstName} ${r.lastName}'),
                      _divider(),
                      _row('E-mail', r.email),
                      _divider(),
                      _row('Telefon', r.phoneNumber),
                      _divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ukupan iznos',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              _formatPrice(r.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF5B5FC7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5FC7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      MainScreen.switchToTab(2);
                    },
                    child: const Text('Moje rezervacije', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Pocetna', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}
