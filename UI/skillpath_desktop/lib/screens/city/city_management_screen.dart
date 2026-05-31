import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _CityItem {
  final int id;
  final String name;
  final int countryId;
  final String countryName;

  _CityItem({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
  });

  factory _CityItem.fromJson(Map<String, dynamic> json) {
    return _CityItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      countryId: json['countryId'] as int? ?? 0,
      countryName: json['countryName'] as String? ?? '',
    );
  }
}

class _CountryOption {
  final int id;
  final String name;
  _CountryOption({required this.id, required this.name});
}

class CityManagementScreen extends StatefulWidget {
  const CityManagementScreen({super.key});

  @override
  State<CityManagementScreen> createState() => _CityManagementScreenState();
}

class _CityManagementScreenState extends State<CityManagementScreen> {
  bool _isLoading = false;
  List<_CityItem> _cities = [];
  List<_CountryOption> _countries = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiClient.get('/api/City'),
        ApiClient.get('/api/Country'),
      ]);

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body) as List<dynamic>;
        _cities = data
            .map((e) => _CityItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body) as List<dynamic>;
        _countries = data
            .map((e) => _CountryOption(
                  id: e['id'] as int,
                  name: e['name'] as String,
                ))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showFormDialog({_CityItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final isEdit = existing != null;
    int? selectedCountryId = existing?.countryId ??
        (_countries.isNotEmpty ? _countries.first.id : null);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Uredi grad' : 'Novi grad'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Naziv grada'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Unesite naziv grada'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCountryId,
                    decoration: const InputDecoration(labelText: 'Drzava'),
                    items: _countries
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedCountryId = v),
                    validator: (v) => v == null ? 'Odaberite drzavu' : null,
                  ),
                ],
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
                final body = {
                  'name': nameCtrl.text.trim(),
                  'countryId': selectedCountryId,
                };
                if (isEdit) {
                  await ApiClient.put('/api/City/${existing.id}', body);
                } else {
                  await ApiClient.post('/api/City', body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchData();
              },
              child: Text(isEdit ? 'Sacuvaj' : 'Kreiraj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCity(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da zelite obrisati grad "$name"?'),
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
      final response = await ApiClient.delete('/api/City/$id');
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
      _fetchData();
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
              const Text('Upravljanje gradovima',
                  style: AppTheme.headingLarge),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Novi grad'),
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
                    : _cities.isEmpty
                        ? const Center(
                            child: Text('Nema gradova',
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
                                  label: Text('Drzava'),
                                  size: ColumnSize.L),
                              DataColumn2(
                                  label: Text('Akcije'),
                                  fixedWidth: 120),
                            ],
                            rows: _cities.map((city) {
                              return DataRow2(cells: [
                                DataCell(Text(city.id.toString(),
                                    style: AppTheme.bodySmall)),
                                DataCell(Text(city.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))),
                                DataCell(Text(city.countryName,
                                    style: AppTheme.bodySmall)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 18),
                                      tooltip: 'Uredi',
                                      onPressed: () =>
                                          _showFormDialog(existing: city),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded,
                                          size: 18, color: AppTheme.error),
                                      tooltip: 'Obrisi',
                                      onPressed: () =>
                                          _deleteCity(city.id, city.name),
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
