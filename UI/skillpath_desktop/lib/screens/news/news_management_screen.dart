import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../widgets/loading_widget.dart';

class _NewsItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String createdByName;

  _NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.createdByName,
  });

  factory _NewsItem.fromJson(Map<String, dynamic> json) {
    return _NewsItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      createdByName: json['createdByName'] as String? ?? '',
    );
  }
}

class NewsManagementScreen extends StatefulWidget {
  const NewsManagementScreen({super.key});

  @override
  State<NewsManagementScreen> createState() => _NewsManagementScreenState();
}

class _NewsManagementScreenState extends State<NewsManagementScreen> {
  bool _isLoading = false;
  List<_NewsItem> _news = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  Future<void> _fetchNews({int? page}) async {
    if (page != null) _currentPage = page;
    setState(() => _isLoading = true);

    try {
      final response =
          await ApiClient.get('/api/News?page=$_currentPage&pageSize=$_pageSize');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _news = (data['items'] as List<dynamic>?)
                ?.map(
                    (e) => _NewsItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _showFormDialog({_NewsItem? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl =
        TextEditingController(text: existing?.content ?? '');
    final imageCtrl =
        TextEditingController(text: existing?.imageUrl ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Uredi novost' : 'Nova novost'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Naslov'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Sadrzaj'),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageCtrl,
                  decoration:
                      const InputDecoration(labelText: 'URL slike (opciono)'),
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
              final body = {
                'title': titleCtrl.text.trim(),
                'content': contentCtrl.text.trim(),
                'imageUrl': imageCtrl.text.trim().isNotEmpty
                    ? imageCtrl.text.trim()
                    : null,
              };

              if (isEdit) {
                await ApiClient.put('/api/News/${existing.id}', body);
              } else {
                await ApiClient.post('/api/News', body);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              _fetchNews();
            },
            child: Text(isEdit ? 'Sacuvaj' : 'Kreiraj'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNews(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content:
            Text('Da li ste sigurni da zelite obrisati novost "$title"?'),
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
      await ApiClient.delete('/api/News/$id');
      _fetchNews();
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
              const Text('Upravljanje novostima',
                  style: AppTheme.headingLarge),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nova novost'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: AppTheme.cardDecoration,
              child: _isLoading
                  ? const LoadingWidget()
                  : _news.isEmpty
                      ? const Center(
                          child: Text('Nema novosti za prikaz',
                              style: AppTheme.bodySmall))
                      : Column(
                          children: [
                            Expanded(
                              child: DataTable2(
                                columnSpacing: 16,
                                horizontalMargin: 20,
                                minWidth: 700,
                                headingRowHeight: 52,
                                dataRowHeight: 64,
                                columns: const [
                                  DataColumn2(
                                      label: Text('Naslov'),
                                      size: ColumnSize.M),
                                  DataColumn2(
                                      label: Text('Sadrzaj'),
                                      size: ColumnSize.L),
                                  DataColumn2(
                                      label: Text('Autor'),
                                      size: ColumnSize.S),
                                  DataColumn2(
                                      label: Text('Datum'),
                                      size: ColumnSize.S),
                                  DataColumn2(
                                      label: Text('Akcije'),
                                      fixedWidth: 120),
                                ],
                                rows: _news.map((n) {
                                  return DataRow2(cells: [
                                    DataCell(Row(
                                      children: [
                                        if (n.imageUrl != null &&
                                            n.imageUrl!.isNotEmpty) ...[
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: Image.network(
                                              n.imageUrl!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )),
                                    DataCell(Text(
                                      n.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodySmall,
                                    )),
                                    DataCell(Text(n.createdByName)),
                                    DataCell(Text(
                                      DateFormat('dd.MM.yyyy')
                                          .format(n.createdAt),
                                      style: AppTheme.bodySmall,
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 18),
                                          tooltip: 'Uredi',
                                          onPressed: () =>
                                              _showFormDialog(existing: n),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.delete_rounded,
                                              size: 18,
                                              color: AppTheme.error),
                                          tooltip: 'Obrisi',
                                          onPressed: () =>
                                              _deleteNews(n.id, n.title),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                            if (_totalPages > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: Color(0xFFE0E0E0))),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.chevron_left_rounded),
                                      onPressed: _currentPage > 1
                                          ? () => _fetchNews(
                                              page: _currentPage - 1)
                                          : null,
                                    ),
                                    Text(
                                        'Stranica $_currentPage od $_totalPages',
                                        style: AppTheme.bodySmall),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.chevron_right_rounded),
                                      onPressed:
                                          _currentPage < _totalPages
                                              ? () => _fetchNews(
                                                  page: _currentPage + 1)
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
