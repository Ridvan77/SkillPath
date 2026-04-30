import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/notification_management_provider.dart';
import '../../widgets/loading_widget.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  List<String> _statusFilters = [];
  List<String> _typeFilters = [];
  DateTime? _scheduledDateTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationManagementProvider>().fetchNotifications();
    });
  }

  List<NotificationItem> _filteredNotifications(
      List<NotificationItem> all) {
    var result = all;
    if (_statusFilters.isNotEmpty) {
      result = result.where((n) => _statusFilters.contains(n.status)).toList();
    }
    if (_typeFilters.isNotEmpty) {
      result = result.where((n) => _typeFilters.contains(_getTypeLabel(n.type))).toList();
    }
    return result;
  }

  String _getTypeLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('promot') || t == 'promotion') return 'Promotivna';
    if (t.contains('course')) return 'Tehnička';
    return 'Informativna';
  }

  String _mapTargetGroup(String group) {
    switch (group.toLowerCase()) {
      case 'all':
        return 'Svi';
      case 'students':
        return 'Studenti';
      case 'instructors':
        return 'Instruktori';
      default:
        return group;
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'Sent':
        return 'Poslata';
      case 'Scheduled':
        return 'Zakazana';
      case 'Draft':
        return 'Nacrt';
      default:
        return status;
    }
  }

  Future<void> _submitNotification(
    BuildContext ctx,
    TextEditingController titleCtrl,
    TextEditingController contentCtrl,
    int selectedType,
    String targetGroup,
  ) async {
    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naslov i poruka su obavezni')),
      );
      return;
    }
    final scheduled = _scheduledDateTime;
    final success = await context
        .read<NotificationManagementProvider>()
        .createNotification(
          title: titleCtrl.text.trim(),
          content: contentCtrl.text.trim(),
          type: selectedType,
          targetGroup: targetGroup,
          scheduledAt: scheduled,
        );
    if (success && ctx.mounted) {
      Navigator.pop(ctx);
      _scheduledDateTime = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scheduled != null
              ? 'Notifikacija zakazana'
              : 'Notifikacija poslana'),
        ),
      );
    }
  }

  void _showCreateDialog() {
    _scheduledDateTime = null;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    int selectedType = 0;
    String targetGroup = 'all';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 550,
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Nova Notifikacija',
                              style: AppTheme.headingSmall),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Naslov *',
                        hintText: 'Unesite naslov notifikacije',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Poruka *',
                        hintText: 'Unesite sadržaj poruke (max 200 karaktera)',
                        counterText: '',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text('Tip notifikacije',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    ..._buildTypeTiles(selectedType, (v) {
                      setDialogState(() => selectedType = v);
                    }),
                    const SizedBox(height: 20),
                    const Text('Ciljna grupa primatelja',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    ..._buildTargetTiles(targetGroup, (v) {
                      setDialogState(() => targetGroup = v);
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppTheme.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifikacije se šalju u realnom vremenu putem FCM servisa. '
                              'Korisnici će biti obaviješteni na svojim uređajima.',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Schedule option
                    const Text('Zakazivanje (opcionalno)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null && ctx.mounted) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setDialogState(() {
                              _scheduledDateTime = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Datum i vrijeme slanja',
                          suffixIcon: _scheduledDateTime != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setDialogState(
                                      () => _scheduledDateTime = null),
                                )
                              : const Icon(Icons.calendar_today_rounded, size: 18),
                        ),
                        child: Text(
                          _scheduledDateTime != null
                              ? DateFormat('dd.MM.yyyy HH:mm')
                                  .format(_scheduledDateTime!)
                              : 'Pošalji odmah',
                          style: TextStyle(
                            color: _scheduledDateTime != null
                                ? null
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _scheduledDateTime != null
                              ? Icons.schedule_rounded
                              : Icons.send_rounded,
                          size: 18,
                        ),
                        label: Text(_scheduledDateTime != null
                            ? 'Zakaži'
                            : 'Pošalji'),
                        onPressed: () => _submitNotification(
                          ctx, titleCtrl, contentCtrl, selectedType,
                          targetGroup,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTypeTiles(int selected, ValueChanged<int> onChanged) {
    const types = [
      {
        'value': 0,
        'label': 'Informativna',
        'desc': 'Opće informacije i najave',
        'icon': Icons.info_outline_rounded
      },
      {
        'value': 1,
        'label': 'Promotivna',
        'desc': 'Popusti i kampanje',
        'icon': Icons.local_offer_rounded
      },
      {
        'value': 2,
        'label': 'Tehnička',
        'desc': 'Sistemske obavijesti',
        'icon': Icons.settings_rounded
      },
    ];

    return types.map((t) {
      final value = t['value'] as int;
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(t['icon'] as IconData,
                    size: 20,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? AppTheme.primary : null,
                          )),
                      Text(t['desc'] as String,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTargetTiles(
      String selected, ValueChanged<String> onChanged) {
    const groups = [
      {
        'value': 'all',
        'label': 'Svi korisnici',
        'icon': Icons.groups_rounded
      },
      {
        'value': 'students',
        'label': 'Samo korisnici',
        'icon': Icons.school_rounded
      },
      {
        'value': 'instructors',
        'label': 'Samo predavači',
        'icon': Icons.person_search_rounded
      },
    ];

    return groups.map((g) {
      final value = g['value'] as String;
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Icon(g['icon'] as IconData,
                    size: 20,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(g['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? AppTheme.primary : null,
                      )),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _showRescheduleDialog(NotificationItem n) async {
    DateTime selectedDate = n.scheduledAt ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (time == null || !mounted) return;

    final newDateTime = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );

    final success = await context
        .read<NotificationManagementProvider>()
        .rescheduleNotification(n.id, newDateTime);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Notifikacija zakazana za ${DateFormat('dd.MM.yyyy HH:mm').format(newDateTime)}'),
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje notifikacije'),
        content: Text('Da li ste sigurni da želite obrisati "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context
          .read<NotificationManagementProvider>()
          .deleteNotification(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikacija obrisana')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationManagementProvider>(
      builder: (context, provider, _) {
        final filtered = _filteredNotifications(provider.notifications);
        final total = provider.totalCount;
        final scheduledCount = provider.notifications.where((n) => n.status == 'Scheduled').length;
        final sentCount = provider.notifications.where((n) => n.status == 'Sent').length;

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upravljanje Notifikacijama',
                          style: AppTheme.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Kreirajte i zakažite obavještenja za korisnike i predavače',
                        style: AppTheme.bodySmall
                            .copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nova Notifikacija'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4 Summary cards
              Row(
                children: [
                  _SummaryCard(
                    label: 'Ukupno',
                    value: total.toString(),
                    icon: Icons.notifications_outlined,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Zakazane',
                    value: scheduledCount.toString(),
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Poslate',
                    value: sentCount.toString(),
                    icon: Icons.send_rounded,
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter row
              Row(
                children: [
                  // Status multi-select
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Poslane',
                    selected: _statusFilters.contains('Sent'),
                    onSelected: (v) => setState(() {
                      v ? _statusFilters.add('Sent') : _statusFilters.remove('Sent');
                    }),
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Zakazane',
                    selected: _statusFilters.contains('Scheduled'),
                    onSelected: (v) => setState(() {
                      v ? _statusFilters.add('Scheduled') : _statusFilters.remove('Scheduled');
                    }),
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 20),
                  // Type multi-select
                  const Text('Tip: ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Informativna',
                    selected: _typeFilters.contains('Informativna'),
                    onSelected: (v) => setState(() {
                      v ? _typeFilters.add('Informativna') : _typeFilters.remove('Informativna');
                    }),
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Promotivna',
                    selected: _typeFilters.contains('Promotivna'),
                    onSelected: (v) => setState(() {
                      v ? _typeFilters.add('Promotivna') : _typeFilters.remove('Promotivna');
                    }),
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Tehnička',
                    selected: _typeFilters.contains('Tehnička'),
                    onSelected: (v) => setState(() {
                      v ? _typeFilters.add('Tehnička') : _typeFilters.remove('Tehnička');
                    }),
                    color: const Color(0xFF8B5CF6),
                  ),
                  const Spacer(),
                  if (_statusFilters.isNotEmpty || _typeFilters.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() {
                        _statusFilters.clear();
                        _typeFilters.clear();
                      }),
                      child: const Text('Očisti filtere'),
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
                      : filtered.isEmpty
                          ? const Center(
                              child: Text('Nema notifikacija za prikaz',
                                  style: AppTheme.bodySmall))
                          : Column(
                              children: [
                                Expanded(
                                  child: DataTable2(
                                    columnSpacing: 12,
                                    horizontalMargin: 16,
                                    minWidth: 900,
                                    headingRowHeight: 52,
                                    dataRowHeight: 68,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    columns: const [
                                      DataColumn2(
                                          label: Text('Naslov'),
                                          size: ColumnSize.L),
                                      DataColumn2(
                                          label: Text('Tip'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Primatelji'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Datum/Vrijeme'),
                                          size: ColumnSize.M),
                                      DataColumn2(
                                          label: Text('Status'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Akcije'),
                                          fixedWidth: 100),
                                    ],
                                    rows: filtered.map((n) {
                                      return DataRow2(cells: [
                                        // Naslov + opis
                                        DataCell(
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(n.title,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13)),
                                              const SizedBox(height: 2),
                                              Text(
                                                n.content,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey[500]),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Tip badge
                                        DataCell(
                                            _TypeBadge(type: n.type)),
                                        // Primatelji
                                        DataCell(Text(
                                          _mapTargetGroup(n.targetGroup),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        )),
                                        // Datum
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                Icons
                                                    .calendar_today_rounded,
                                                size: 14,
                                                color: Colors.grey[400]),
                                            const SizedBox(width: 6),
                                            Text(
                                              n.scheduledAt != null
                                                  ? DateFormat(
                                                          'yyyy-MM-dd HH:mm')
                                                      .format(n.scheduledAt!.toLocal())
                                                  : n.sentAt != null
                                                      ? DateFormat(
                                                              'yyyy-MM-dd HH:mm')
                                                          .format(n.sentAt!.toLocal())
                                                      : '-',
                                              style: const TextStyle(
                                                  fontSize: 13),
                                            ),
                                          ],
                                        )),
                                        // Status
                                        DataCell(_StatusBadge(
                                            status: _mapStatus(n.status))),
                                        // Akcije
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (n.status == 'Scheduled')
                                              IconButton(
                                                icon: Icon(
                                                    Icons.schedule_rounded,
                                                    size: 18,
                                                    color: AppTheme.warning),
                                                tooltip: 'Promijeni vrijeme',
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 34,
                                                        minHeight: 34),
                                                onPressed: () =>
                                                    _showRescheduleDialog(n),
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                  Icons
                                                      .delete_outline_rounded,
                                                  size: 18,
                                                  color: AppTheme.error),
                                              tooltip: 'Obriši',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(
                                                      minWidth: 34,
                                                      minHeight: 34),
                                              onPressed: () =>
                                                  _deleteNotification(
                                                      n.id, n.title),
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

  Widget _buildPagination(NotificationManagementProvider provider) {
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
                ? () => provider.fetchNotifications(
                    page: provider.currentPage - 1)
                : null,
          ),
          for (int i = 1; i <= provider.totalPages && i <= 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: i == provider.currentPage
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => provider.fetchNotifications(page: i),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: i == provider.currentPage
                            ? Colors.white
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: provider.currentPage < provider.totalPages
                ? () => provider.fetchNotifications(
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
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
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
                Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    final t = type.toLowerCase();

    if (t.contains('promot') || t == 'promotion') {
      color = const Color(0xFFF59E0B);
      label = 'Promotivna';
    } else if (t.contains('system') || t == 'reservation' || t == 'payment') {
      color = const Color(0xFF3B82F6);
      label = 'Informativna';
    } else if (t.contains('course')) {
      color = const Color(0xFF8B5CF6);
      label = 'Tehnička';
    } else {
      color = const Color(0xFF3B82F6);
      label = 'Informativna';
    }

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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Zakazana':
        color = const Color(0xFFF59E0B);
        break;
      case 'Poslata':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : color,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
