import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _CategoryItem {
  final int id;
  final String name;
  final String? description;
  final int coursesCount;

  _CategoryItem({
    required this.id,
    required this.name,
    this.description,
    required this.coursesCount,
  });

  factory _CategoryItem.fromJson(Map<String, dynamic> json) {
    return _CategoryItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coursesCount: json['coursesCount'] as int? ?? 0,
    );
  }
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  bool _isLoading = false;
  List<_CategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/api/Category');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _categories = data
            .map((e) => _CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showFormDialog({_CategoryItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Uredi kategoriju' : 'Nova kategorija'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Naziv'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Otkazi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final body = {
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
              };

              if (isEdit) {
                await ApiClient.put(
                    '/api/Category/${existing.id}', body);
              } else {
                await ApiClient.post('/api/Category', body);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              _fetchCategories();
            },
            child: Text(isEdit ? 'Sacuvaj' : 'Kreiraj'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content:
            Text('Da li ste sigurni da zelite obrisati kategoriju "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkazi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obrisi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiClient.delete('/api/Category/$id');
      _fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upravljanje kategorijama',
                  style: AppTheme.headingLarge),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nova kategorija'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
              decoration: AppTheme.cardDecoration,
              child: _isLoading
                  ? const LoadingWidget()
                  : _categories.isEmpty
                      ? const Center(
                          child: Text('Nema kategorija',
                              style: AppTheme.bodySmall))
                      : DataTable2(
                          columnSpacing: 16,
                          horizontalMargin: 20,
                          minWidth: 500,
                          headingRowHeight: 52,
                          dataRowHeight: 56,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          columns: const [
                            DataColumn2(
                                label: Text('ID'), fixedWidth: 60),
                            DataColumn2(
                                label: Text('Naziv'),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Opis'),
                                size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Kursevi'),
                                numeric: true,
                                fixedWidth: 100),
                            DataColumn2(
                                label: Text('Akcije'),
                                fixedWidth: 120),
                          ],
                          rows: _categories.map((cat) {
                            return DataRow2(cells: [
                              DataCell(Text(cat.id.toString(),
                                  style: AppTheme.bodySmall)),
                              DataCell(Text(cat.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(
                                cat.description ?? '-',
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodySmall,
                              )),
                              DataCell(Text(cat.coursesCount.toString())),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 18),
                                    tooltip: 'Uredi',
                                    onPressed: () =>
                                        _showFormDialog(existing: cat),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_rounded,
                                        size: 18, color: AppTheme.error),
                                    tooltip: 'Obrisi',
                                    onPressed: () =>
                                        _deleteCategory(cat.id, cat.name),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
