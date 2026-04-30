import 'package:flutter/material.dart';

class ReservationStatusChip extends StatelessWidget {
  final String status;

  const ReservationStatusChip({
    super.key,
    required this.status,
  });

  Color _backgroundColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade50;
      case 'confirmed':
      case 'active':
        return Colors.green.shade50;
      case 'completed':
        return Colors.blue.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _textColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'confirmed':
      case 'active':
        return Colors.green.shade800;
      case 'completed':
        return Colors.blue.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _icon() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
      case 'active':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _label() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Na cekanju';
      case 'confirmed':
        return 'Potvrdjena';
      case 'active':
        return 'Aktivna';
      case 'completed':
        return 'Zavrsena';
      case 'cancelled':
        return 'Otkazana';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 14, color: _textColor()),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor(),
            ),
          ),
        ],
      ),
    );
  }
}
