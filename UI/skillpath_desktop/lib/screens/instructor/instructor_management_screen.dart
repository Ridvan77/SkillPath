import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _InstructorItem {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;
  int courseCount;
  double averageRating;

  _InstructorItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.isActive,
    required this.createdAt,
    this.courseCount = 0,
    this.averageRating = 0.0,
  });

  String get fullName => '$firstName $lastName';

  factory _InstructorItem.fromJson(Map<String, dynamic> json) {
    return _InstructorItem(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class InstructorManagementScreen extends StatefulWidget {
  const InstructorManagementScreen({super.key});

  @override
  State<InstructorManagementScreen> createState() =>
      _InstructorManagementScreenState();
}

class _InstructorManagementScreenState
    extends State<InstructorManagementScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<_InstructorItem> _instructors = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchInstructors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInstructors({int? page}) async {
    if (page != null) _currentPage = page;
    setState(() => _isLoading = true);

    try {
      var endpoint =
          '/api/User?page=$_currentPage&pageSize=$_pageSize&role=Instructor';
      if (_searchController.text.trim().isNotEmpty) {
        endpoint +=
            '&search=${Uri.encodeComponent(_searchController.text.trim())}';
      }

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _instructors = (data['items'] as List<dynamic>?)
                ?.map((e) =>
                    _InstructorItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;

        // Fetch course stats for each instructor
        for (final instructor in _instructors) {
          await _fetchInstructorStats(instructor);
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchInstructorStats(_InstructorItem instructor) async {
    try {
      final response = await ApiClient.get(
          '/api/Course/instructor/${instructor.id}');
      if (response.statusCode == 200) {
        final courses = jsonDecode(response.body) as List<dynamic>;
        instructor.courseCount = courses.length;
        if (courses.isNotEmpty) {
          double totalRating = 0;
          int ratedCount = 0;
          for (final c in courses) {
            final rating = (c['averageRating'] as num?)?.toDouble() ?? 0.0;
            if (rating > 0) {
              totalRating += rating;
              ratedCount++;
            }
          }
          instructor.averageRating =
              ratedCount > 0 ? totalRating / ratedCount : 0.0;
        }
      }
    } catch (_) {}
  }

  Future<void> _softDelete(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deaktivacija predavača'),
        content: const Text(
            'Da li ste sigurni da želite deaktivirati ovog predavača?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktiviraj'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response =
          await ApiClient.put('/api/User/$userId/toggle-active', null);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchInstructors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Predavač deaktiviran')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _hardDelete(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trajno brisanje'),
        content: Text(
            'Da li ste sigurni da želite trajno obrisati predavača "$name"? Ova akcija se ne može poništiti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši trajno'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response = await ApiClient.delete('/api/User/$userId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchInstructors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Predavač trajno obrisan')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _activateUser(String userId) async {
    try {
      final response =
          await ApiClient.put('/api/User/$userId/toggle-active', null);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchInstructors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Predavač aktiviran')),
          );
        }
      }
    } catch (_) {}
  }

  void _showEditDialog(_InstructorItem instructor) {
    final firstNameCtrl =
        TextEditingController(text: instructor.firstName);
    final lastNameCtrl =
        TextEditingController(text: instructor.lastName);
    final phoneCtrl =
        TextEditingController(text: instructor.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Uredi predavača', style: AppTheme.headingSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Ime'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Prezime'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final data = <String, dynamic>{
                          'firstName': firstNameCtrl.text.trim(),
                          'lastName': lastNameCtrl.text.trim(),
                          'phoneNumber': phoneCtrl.text.trim(),
                        };
                        try {
                          final response = await ApiClient.put(
                              '/api/User/${instructor.id}', data);
                          if (response.statusCode == 200) {
                            Navigator.pop(ctx);
                            _fetchInstructors();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Predavač uspješno ažuriran')),
                              );
                            }
                          }
                        } catch (_) {}
                      },
                      child: const Text('Sačuvaj'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructorDetail(_InstructorItem instructor) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Detalji predavača', style: AppTheme.headingSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('Ime i prezime', instructor.fullName),
              _detailRow('Email', instructor.email),
              _detailRow('Telefon', instructor.phoneNumber ?? 'N/A'),
              _detailRow('Broj kurseva', instructor.courseCount.toString()),
              _detailRow('Prosječna ocjena',
                  instructor.averageRating.toStringAsFixed(1)),
              _detailRow(
                  'Status', instructor.isActive ? 'Aktivan' : 'Neaktivan'),
              _detailRow('Registrovan',
                  DateFormat('dd.MM.yyyy HH:mm').format(instructor.createdAt)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Zatvori'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey[600])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upravljanje Predavačima',
                  style: AppTheme.headingLarge),
              const SizedBox(height: 4),
              Text(
                'Pregled i upravljanje svim predavačima u sistemu',
                style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži predavače po imenu ili emailu...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _fetchInstructors(page: 1);
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetchInstructors(page: 1),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: AppTheme.cardDecoration,
                child: _isLoading
                    ? const LoadingWidget()
                    : _instructors.isEmpty
                        ? const Center(
                            child: Text('Nema predavača za prikaz',
                                style: AppTheme.bodySmall))
                        : Column(
                            children: [
                              Expanded(
                                child: DataTable2(
                                  columnSpacing: 16,
                                  horizontalMargin: 20,
                                  minWidth: 800,
                                  headingRowHeight: 52,
                                  dataRowHeight: 56,
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  columns: const [
                                    DataColumn2(
                                        label: Text('Ime i prezime'),
                                        size: ColumnSize.M),
                                    DataColumn2(
                                        label: Text('Email'),
                                        size: ColumnSize.M),
                                    DataColumn2(
                                        label: Text('Telefon'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Br. kurseva'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Prosj. ocjena'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Status'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Akcije'),
                                        fixedWidth: 180),
                                  ],
                                  rows: _instructors.map((instructor) {
                                    return DataRow2(cells: [
                                      DataCell(Text(instructor.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600))),
                                      DataCell(Text(instructor.email)),
                                      DataCell(Text(
                                          instructor.phoneNumber ?? 'N/A')),
                                      DataCell(Text(
                                        instructor.courseCount.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      )),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFFF9800),
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(instructor.averageRating
                                                .toStringAsFixed(1)),
                                          ],
                                        ),
                                      ),
                                      DataCell(_StatusBadge(
                                          isActive: instructor.isActive)),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                                Icons.visibility_outlined,
                                                size: 18,
                                                color: Colors.grey[600]),
                                            tooltip: 'Detalji',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 34,
                                                    minHeight: 34),
                                            onPressed: () =>
                                                _showInstructorDetail(
                                                    instructor),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: Colors.grey[600]),
                                            tooltip: 'Uredi',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 34,
                                                    minHeight: 34),
                                            onPressed: () =>
                                                _showEditDialog(instructor),
                                          ),
                                          if (instructor.isActive)
                                            IconButton(
                                              icon: Icon(
                                                  Icons.block_rounded,
                                                  size: 18,
                                                  color: AppTheme.warning),
                                              tooltip: 'Deaktiviraj',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(
                                                      minWidth: 34,
                                                      minHeight: 34),
                                              onPressed: () =>
                                                  _softDelete(instructor.id),
                                            )
                                          else
                                            IconButton(
                                              icon: Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  size: 18,
                                                  color: AppTheme.success),
                                              tooltip: 'Aktiviraj',
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(
                                                      minWidth: 34,
                                                      minHeight: 34),
                                              onPressed: () =>
                                                  _activateUser(
                                                      instructor.id),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                                Icons
                                                    .delete_outline_rounded,
                                                size: 18,
                                                color: AppTheme.error),
                                            tooltip: 'Obriši trajno',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 34,
                                                    minHeight: 34),
                                            onPressed: () => _hardDelete(
                                                instructor.id,
                                                instructor.fullName),
                                          ),
                                        ],
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                              if (_totalPages > 1) _buildPagination(),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
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
            onPressed: _currentPage > 1
                ? () => _fetchInstructors(page: _currentPage - 1)
                : null,
          ),
          for (int i = 1; i <= _totalPages && i <= 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: i == _currentPage
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _fetchInstructors(page: i),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: i == _currentPage
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
            onPressed: _currentPage < _totalPages
                ? () => _fetchInstructors(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
