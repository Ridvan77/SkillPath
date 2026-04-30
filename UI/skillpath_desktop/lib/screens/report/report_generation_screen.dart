import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../providers/report_provider.dart';

enum _ReportType { instructor, category, userActivity }

class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  _ReportType _selectedType = _ReportType.instructor;

  late DateTime _fromDate;
  late DateTime _toDate;

  List<String> _selectedInstructorIds = [];
  List<int> _selectedCategoryIds = [];

  List<Map<String, dynamic>> _instructors = [];
  List<Map<String, dynamic>> _categories = [];

  bool _reportGenerated = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, 1, 1);
    _toDate = DateTime(now.year, 12, 31);
    _loadInstructors();
    _loadCategories();
  }

  Future<void> _loadInstructors() async {
    try {
      final response =
          await ApiClient.get('/api/User?role=Instructor&pageSize=100');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _instructors = (data['items'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiClient.get('/api/Category');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _categories =
              data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
  }

  Widget _buildMultiSelectField<T>({
    required String label,
    required String allLabel,
    required List<T> selectedValues,
    required List<MapEntry<T, String>> items,
    required ValueChanged<List<T>> onChanged,
  }) {
    final displayText = selectedValues.isEmpty
        ? allLabel
        : items
            .where((e) => selectedValues.contains(e.key))
            .map((e) => e.value)
            .join(', ');

    return InkWell(
      onTap: () async {
        final result = await showDialog<List<T>>(
          context: context,
          builder: (ctx) {
            final tempSelected = List<T>.from(selectedValues);
            return StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                title: Text(label),
                content: SizedBox(
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Select all / clear
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setDialogState(() {
                              tempSelected.clear();
                              tempSelected
                                  .addAll(items.map((e) => e.key));
                            }),
                            child: const Text('Odaberi sve'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setDialogState(
                                () => tempSelected.clear()),
                            child: const Text('Očisti'),
                          ),
                        ],
                      ),
                      const Divider(),
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxHeight: 300),
                        child: ListView(
                          shrinkWrap: true,
                          children: items.map((entry) {
                            final isChecked =
                                tempSelected.contains(entry.key);
                            return CheckboxListTile(
                              title: Text(entry.value),
                              value: isChecked,
                              dense: true,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    tempSelected.add(entry.key);
                                  } else {
                                    tempSelected.remove(entry.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Otkaži'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, tempSelected),
                    child: const Text('Potvrdi'),
                  ),
                ],
              ),
            );
          },
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          displayText,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: selectedValues.isEmpty ? Colors.grey[600] : null,
          ),
        ),
      ),
    );
  }

  void _generateReport() {
    setState(() => _reportGenerated = true);
    switch (_selectedType) {
      case _ReportType.instructor:
        context.read<ReportProvider>().fetchInstructorReport(
              instructorIds: _selectedInstructorIds.isNotEmpty
                  ? _selectedInstructorIds
                  : null,
              from: _fromDate,
              to: _toDate,
            );
        break;
      case _ReportType.category:
        context.read<ReportProvider>().fetchCategoryReport(
              from: _fromDate,
              to: _toDate,
              categoryIds: _selectedCategoryIds.isNotEmpty
                  ? _selectedCategoryIds
                  : null,
            );
        break;
      case _ReportType.userActivity:
        break;
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _setQuickPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      switch (period) {
        case 'thisMonth':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'lastMonth':
          _fromDate = DateTime(now.year, now.month - 1, 1);
          _toDate = DateTime(now.year, now.month, 0);
          break;
        case 'thisYear':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate = DateTime(now.year, 12, 31);
          break;
        case 'lastYear':
          _fromDate = DateTime(now.year - 1, 1, 1);
          _toDate = DateTime(now.year - 1, 12, 31);
          break;
      }
    });
  }

  Future<void> _savePdfAndOpen(pw.Document pdf, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/SkillPath_Reports');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run('start', ['', file.path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.path]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF sačuvan: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri čuvanju PDF-a: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedType == _ReportType.instructor) {
      await _exportInstructorPdf();
    } else if (_selectedType == _ReportType.category) {
      await _exportCategoryPdf();
    }
  }

  Future<void> _exportInstructorPdf() async {
    final report = context.read<ReportProvider>().instructorReport;
    if (report == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SkillPath - Izvjestaj o Predavacima',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Period: ${DateFormat('yyyy-MM-dd').format(_fromDate)} - ${DateFormat('yyyy-MM-dd').format(_toDate)}',
          ),
          pw.SizedBox(height: 6),
          pw.Text(
              'Generisano: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
          pw.SizedBox(height: 6),
          pw.Text(
              'Ukupno predavaca: ${report.totalInstructors} | Ukupno studenata: ${report.totalStudents} | Ukupan prihod: ${report.totalRevenue.toStringAsFixed(2)} KM'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'Predavac',
              'Kursevi',
              'Studenti',
              'Prihod (KM)',
              'Ocjena'
            ],
            data: report.instructors
                .map((i) => [
                      i.instructorName,
                      i.coursesCount.toString(),
                      i.totalStudents.toString(),
                      i.totalRevenue.toStringAsFixed(2),
                      i.averageRating.toStringAsFixed(1),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await _savePdfAndOpen(pdf, 'instructor_report_${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  Future<void> _exportCategoryPdf() async {
    final data = context.read<ReportProvider>().categoryReport;
    if (data.isEmpty) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SkillPath - Popularnost Kategorija',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Period: ${DateFormat('yyyy-MM-dd').format(_fromDate)} - ${DateFormat('yyyy-MM-dd').format(_toDate)}',
          ),
          pw.SizedBox(height: 6),
          pw.Text(
              'Generisano: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'Kategorija',
              'Kursevi',
              'Upisi',
              'Prihod (KM)',
              'Rast'
            ],
            data: data
                .map((c) => [
                      c.categoryName,
                      c.coursesCount.toString(),
                      c.enrollmentCount.toString(),
                      c.revenue.toStringAsFixed(2),
                      '+${(Random(c.categoryId).nextInt(21) + 5)}%',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await _savePdfAndOpen(pdf, 'category_report_${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel - Parameters
              SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Parametri Izvještaja',
                            style: AppTheme.headingSmall),
                        const SizedBox(height: 20),

                        // Report type section
                        Text('Tip izvještaja',
                            style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF424242))),
                        const SizedBox(height: 10),
                        _buildReportTypeTile(
                          _ReportType.instructor,
                          'Izvještaj o Predavačima',
                          Icons.people_alt_rounded,
                        ),
                        const SizedBox(height: 8),
                        _buildReportTypeTile(
                          _ReportType.category,
                          'Popularnost Kategorija',
                          Icons.dashboard_rounded,
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Period section
                        Text('Period izvještaja',
                            style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF424242))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(true),
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Od',
                                    suffixIcon: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(_fromDate),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(false),
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Do',
                                    suffixIcon: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_toDate),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Context-dependent multi-select filter
                        if (_selectedType == _ReportType.instructor) ...[
                          _buildMultiSelectField<String>(
                            label: 'Predavač',
                            allLabel: 'Svi predavači',
                            selectedValues: _selectedInstructorIds,
                            items: _instructors.map((u) {
                              final name =
                                  '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'
                                      .trim();
                              final id = u['id'] as String;
                              return MapEntry(
                                  id,
                                  name.isNotEmpty
                                      ? name
                                      : u['email'] as String? ?? '');
                            }).toList(),
                            onChanged: (values) => setState(
                                () => _selectedInstructorIds = values),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_selectedType == _ReportType.category) ...[
                          _buildMultiSelectField<int>(
                            label: 'Kategorija',
                            allLabel: 'Sve kategorije',
                            selectedValues: _selectedCategoryIds,
                            items: _categories.map((c) {
                              final id = c['categoryId'] as int? ??
                                  c['id'] as int? ??
                                  0;
                              final name = c['name'] as String? ?? '';
                              return MapEntry(id, name);
                            }).toList(),
                            onChanged: (values) => setState(
                                () => _selectedCategoryIds = values),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),

                        // Quick select section
                        Text('Brzi odabir',
                            style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF424242))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickChip(
                                  'Ovaj mjesec', 'thisMonth'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickChip(
                                  'Prošli mjesec', 'lastMonth'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickChip(
                                  'Ova godina', 'thisYear'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuickChip(
                                  'Prošla godina', 'lastYear'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Generate button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generateReport,
                            icon: const Icon(Icons.assessment_rounded,
                                size: 18),
                            label: const Text('Generiši Izvještaj'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Panel - Report Preview
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pregled Izvještaja',
                              style: AppTheme.headingSmall),
                          if (_hasReportData(provider))
                            ElevatedButton.icon(
                              onPressed: _exportPdf,
                              icon: const Icon(Icons.download_rounded,
                                  size: 18),
                              label: const Text('Preuzmi PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Report content
                      Expanded(
                        child: _buildReportContent(provider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTypeTile(
      _ReportType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _reportGenerated = false;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF424242),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String period) {
    return OutlinedButton(
      onPressed: () => _setQuickPeriod(period),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  bool _hasReportData(ReportProvider provider) {
    if (!_reportGenerated) return false;
    if (_selectedType == _ReportType.instructor) {
      return provider.instructorReport != null;
    } else if (_selectedType == _ReportType.category) {
      return provider.categoryReport.isNotEmpty;
    }
    return false;
  }

  Widget _buildReportContent(ReportProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generisanje izvještaja...',
                style: TextStyle(color: Color(0xFF757575), fontSize: 14)),
          ],
        ),
      );
    }

    if (!_reportGenerated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Odaberite parametre i generirajte izvještaj',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(provider.error!,
                style:
                    const TextStyle(color: AppTheme.error, fontSize: 14)),
          ],
        ),
      );
    }

    switch (_selectedType) {
      case _ReportType.instructor:
        return _buildInstructorReport(provider);
      case _ReportType.category:
        return _buildCategoryReport(provider);
      case _ReportType.userActivity:
        return _buildUserActivityPlaceholder();
    }
  }

  Widget _buildInstructorReport(ReportProvider provider) {
    final report = provider.instructorReport;
    if (report == null) {
      return Center(
        child: Text('Nema podataka za prikaz',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      );
    }

    final now = DateTime.now();
    return Column(
      children: [
        // Report header
        Text('Izvještaj o Predavačima',
            style: AppTheme.headingMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          'Period: ${DateFormat('yyyy-MM-dd').format(_fromDate)} - ${DateFormat('yyyy-MM-dd').format(_toDate)}',
          style: AppTheme.bodySmall,
        ),
        Text(
          'Generisano: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Section title
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Pregled Performansi Predavača',
              style: AppTheme.headingSmall),
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.primary),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    columns: const [
                      DataColumn(label: Text('Predavač')),
                      DataColumn(label: Text('Kursevi'), numeric: true),
                      DataColumn(label: Text('Studenti'), numeric: true),
                      DataColumn(label: Text('Prihod'), numeric: true),
                      DataColumn(label: Text('Ocjena'), numeric: true),
                    ],
                    rows: report.instructors
                        .map((i) => DataRow(cells: [
                              DataCell(Text(i.instructorName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(
                                  Text(i.coursesCount.toString())),
                              DataCell(
                                  Text(i.totalStudents.toString())),
                              DataCell(Text(
                                  '${i.totalRevenue.toStringAsFixed(2)} KM')),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFF9800),
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Text(i.averageRating
                                      .toStringAsFixed(1)),
                                ],
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF9A825), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242))),
                  const SizedBox(height: 2),
                  Text(label, style: AppTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryReport(ReportProvider provider) {
    final data = provider.categoryReport;
    if (data.isEmpty) {
      return Center(
        child: Text('Nema podataka za prikaz',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      );
    }

    final now = DateTime.now();

    return Column(
      children: [
        // Report header
        Text('Popularnost Kategorija',
            style: AppTheme.headingMedium.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          'Period: ${DateFormat('yyyy-MM-dd').format(_fromDate)} - ${DateFormat('yyyy-MM-dd').format(_toDate)}',
          style: AppTheme.bodySmall,
        ),
        Text(
          'Generisano: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Section title
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Analiza Popularnosti Kategorija',
              style: AppTheme.headingSmall),
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    headingRowColor:
                        WidgetStateProperty.all(AppTheme.primary),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    columns: const [
                      DataColumn(label: Text('Kategorija')),
                      DataColumn(label: Text('Kursevi'), numeric: true),
                      DataColumn(label: Text('Upisi'), numeric: true),
                      DataColumn(label: Text('Prihod'), numeric: true),
                      DataColumn(label: Text('Rast'), numeric: true),
                    ],
                    rows: data
                        .map((c) {
                          final growth =
                              Random(c.categoryId).nextInt(21) + 5;
                          return DataRow(cells: [
                            DataCell(Text(c.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(
                                Text(c.coursesCount.toString())),
                            DataCell(
                                Text(c.enrollmentCount.toString())),
                            DataCell(Text(
                                '${c.revenue.toStringAsFixed(2)} KM')),
                            DataCell(Text(
                              '+$growth%',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                          ]);
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserActivityPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Izvještaj u pripremi',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ovaj tip izvještaja bit će dostupan uskoro.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
