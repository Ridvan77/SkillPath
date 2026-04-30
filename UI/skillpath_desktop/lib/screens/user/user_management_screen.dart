import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _UserItem {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;
  final int reservationCount;

  _UserItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.isActive,
    required this.createdAt,
    required this.reservationCount,
  });

  String get fullName => '$firstName $lastName';

  factory _UserItem.fromJson(Map<String, dynamic> json) {
    return _UserItem(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      reservationCount: json['reservationCount'] as int? ?? 0,
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<_UserItem> _users = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({int? page}) async {
    if (page != null) _currentPage = page;
    setState(() => _isLoading = true);

    try {
      var endpoint =
          '/api/User?page=$_currentPage&pageSize=$_pageSize&role=Student';
      if (_searchController.text.trim().isNotEmpty) {
        endpoint +=
            '&search=${Uri.encodeComponent(_searchController.text.trim())}';
      }

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _users = (data['items'] as List<dynamic>?)
                ?.map(
                    (e) => _UserItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _softDelete(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deaktivacija korisnika'),
        content: const Text(
            'Da li ste sigurni da želite deaktivirati ovog korisnika? Korisnik neće moći pristupiti sistemu.'),
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
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Korisnik deaktiviran')),
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
            'Da li ste sigurni da želite trajno obrisati korisnika "$name"? Ova akcija se ne može poništiti.'),
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
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Korisnik trajno obrisan')),
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
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Korisnik aktiviran')),
          );
        }
      }
    } catch (_) {}
  }

  void _showEditDialog(_UserItem user) {
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');

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
                        'Uredi korisnika', style: AppTheme.headingSmall),
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
                              '/api/User/${user.id}', data);
                          if (response.statusCode == 200) {
                            Navigator.pop(ctx);
                            _fetchUsers();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Korisnik uspješno ažuriran')),
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

  void _showUserDetail(_UserItem user) {
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
                    child:
                        Text('Detalji korisnika', style: AppTheme.headingSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('Ime i prezime', user.fullName),
              _detailRow('Email', user.email),
              _detailRow('Telefon', user.phoneNumber ?? 'N/A'),
              _detailRow(
                  'Status', user.isActive ? 'Aktivan' : 'Neaktivan'),
              _detailRow('Registrovan',
                  DateFormat('dd.MM.yyyy HH:mm').format(user.createdAt)),
              _detailRow('Rezervacije', user.reservationCount.toString()),
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
            width: 120,
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
              const Text('Upravljanje Korisnicima',
                  style: AppTheme.headingLarge),
              const SizedBox(height: 4),
              Text(
                'Pregled i upravljanje svim korisnicima u sistemu',
                style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži korisnike po imenu ili emailu...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _fetchUsers(page: 1);
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetchUsers(page: 1),
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
                    : _users.isEmpty
                        ? const Center(
                            child: Text('Nema korisnika za prikaz',
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
                                        label: Text('Registrovan'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Rezervacije'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Status'),
                                        size: ColumnSize.S),
                                    DataColumn2(
                                        label: Text('Akcije'),
                                        fixedWidth: 180),
                                  ],
                                  rows: _users.map((user) {
                                    return DataRow2(cells: [
                                      DataCell(Text(user.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600))),
                                      DataCell(Text(user.email)),
                                      DataCell(
                                          Text(user.phoneNumber ?? 'N/A')),
                                      DataCell(Text(
                                        DateFormat('dd.MM.yyyy')
                                            .format(user.createdAt),
                                        style: AppTheme.bodySmall,
                                      )),
                                      DataCell(Text(
                                        user.reservationCount.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      )),
                                      DataCell(_StatusBadge(
                                          isActive: user.isActive)),
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
                                                _showUserDetail(user),
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
                                                _showEditDialog(user),
                                          ),
                                          if (user.isActive)
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
                                                  _softDelete(user.id),
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
                                                  _activateUser(user.id),
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
                                                user.id, user.fullName),
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
                ? () => _fetchUsers(page: _currentPage - 1)
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
                  onTap: () => _fetchUsers(page: i),
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
                ? () => _fetchUsers(page: _currentPage + 1)
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
