import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _CountryItem {
  final int id;
  final String name;
  final int cityCount;

  _CountryItem({required this.id, required this.name, required this.cityCount});

  factory _CountryItem.fromJson(Map<String, dynamic> json) {
    return _CountryItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      cityCount: json['cityCount'] as int? ?? 0,
    );
  }
}

class CountryManagementScreen extends StatefulWidget {
  const CountryManagementScreen({super.key});

  @override
  State<CountryManagementScreen> createState() =>
      _CountryManagementScreenState();
}

class _CountryManagementScreenState extends State<CountryManagementScreen> {
  bool _isLoading = false;
  List<_CountryItem> _countries = [];

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/api/Country');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _countries = data
            .map((e) => _CountryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showFormDialog({_CountryItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Uredi drzavu' : 'Nova drzava'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Naziv drzave'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Unesite naziv drzave'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Otkazi'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final body = {'name': nameCtrl.text.trim()};
              if (isEdit) {
                await ApiClient.put('/api/Country/${existing.id}', body);
              } else {
                await ApiClient.post('/api/Country', body);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _fetchCountries();
            },
            child: Text(isEdit ? 'Sacuvaj' : 'Kreiraj'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCountry(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content:
            Text('Da li ste sigurni da zelite obrisati drzavu "$name"?'),
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
      final response = await ApiClient.delete('/api/Country/$id');
      if (response.statusCode != 204 && response.statusCode != 200 && mounted) {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(body['error']?['message'] ?? 'Greska pri brisanju.')),
          );
        } catch (_) {}
      }
      _fetchCountries();
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
              const Text('Upravljanje drzavama',
                  style: AppTheme.headingLarge),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nova drzava'),
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
                    : _countries.isEmpty
                        ? const Center(
                            child: Text('Nema drzava',
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
                                  size: ColumnSize.L),
                              DataColumn2(
                                  label: Text('Gradovi'),
                                  numeric: true,
                                  fixedWidth: 100),
                              DataColumn2(
                                  label: Text('Akcije'),
                                  fixedWidth: 120),
                            ],
                            rows: _countries.map((country) {
                              return DataRow2(cells: [
                                DataCell(Text(country.id.toString(),
                                    style: AppTheme.bodySmall)),
                                DataCell(Text(country.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))),
                                DataCell(
                                    Text(country.cityCount.toString())),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 18),
                                      tooltip: 'Uredi',
                                      onPressed: () =>
                                          _showFormDialog(existing: country),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded,
                                          size: 18, color: AppTheme.error),
                                      tooltip: 'Obrisi',
                                      onPressed: () => _deleteCountry(
                                          country.id, country.name),
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
