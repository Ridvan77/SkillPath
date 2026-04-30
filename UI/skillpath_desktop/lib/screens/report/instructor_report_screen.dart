import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/loading_widget.dart';

class InstructorReportScreen extends StatefulWidget {
  const InstructorReportScreen({super.key});

  @override
  State<InstructorReportScreen> createState() =>
      _InstructorReportScreenState();
}

class _InstructorReportScreenState extends State<InstructorReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedInstructorId;
  List<Map<String, dynamic>> _instructors = [];

  @override
  void initState() {
    super.initState();
    _loadInstructors();
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

  void _generateReport() {
    context.read<ReportProvider>().fetchInstructorReport(
          instructorId: _selectedInstructorId,
          from: _fromDate,
          to: _toDate,
        );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  Future<void> _exportPdf() async {
    final report = context.read<ReportProvider>().instructorReport;
    if (report == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SkillPath - Izvjestaj o instruktorima',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Period: ${report.fromDate != null ? DateFormat('dd.MM.yyyy').format(report.fromDate!) : 'Od pocetka'} - ${report.toDate != null ? DateFormat('dd.MM.yyyy').format(report.toDate!) : 'Do danas'}',
          ),
          pw.SizedBox(height: 6),
          pw.Text(
              'Ukupno instruktora: ${report.totalInstructors} | Ukupno studenata: ${report.totalStudents} | Ukupan prihod: ${report.totalRevenue.toStringAsFixed(2)} KM'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'Instruktor',
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

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'instructor_report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
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
              // Left: filters
              SizedBox(
                width: 320,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Izvjestaj o instruktorima',
                          style: AppTheme.headingSmall),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedInstructorId,
                        decoration: const InputDecoration(
                            labelText: 'Instruktor (opciono)'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Svi instruktori')),
                          ..._instructors.map((u) {
                            final name =
                                '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'
                                    .trim();
                            return DropdownMenuItem(
                              value: u['id'] as String,
                              child: Text(name.isNotEmpty
                                  ? name
                                  : u['email'] as String? ?? ''),
                            );
                          }),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedInstructorId = v),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Od datuma'),
                          child: Text(
                            _fromDate != null
                                ? DateFormat('dd.MM.yyyy')
                                    .format(_fromDate!)
                                : 'Odaberite datum',
                            style: TextStyle(
                                color: _fromDate != null
                                    ? null
                                    : Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Do datuma'),
                          child: Text(
                            _toDate != null
                                ? DateFormat('dd.MM.yyyy').format(_toDate!)
                                : 'Odaberite datum',
                            style: TextStyle(
                                color:
                                    _toDate != null ? null : Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateReport,
                          icon: const Icon(Icons.assessment_rounded,
                              size: 18),
                          label: const Text('Generiraj'),
                        ),
                      ),
                      if (provider.instructorReport != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                size: 18),
                            label: const Text('Izvezi PDF'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right: results
              Expanded(
                child: provider.isLoading
                    ? const LoadingWidget(message: 'Generisanje izvjestaja...')
                    : provider.instructorReport == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assessment_rounded,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Odaberite parametre i generirajte izvjestaj',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary row
                              Row(
                                children: [
                                  _StatBadge(
                                    label: 'Instruktori',
                                    value: provider
                                        .instructorReport!.totalInstructors
                                        .toString(),
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  _StatBadge(
                                    label: 'Studenti',
                                    value: provider
                                        .instructorReport!.totalStudents
                                        .toString(),
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 16),
                                  _StatBadge(
                                    label: 'Prihod',
                                    value:
                                        '${provider.instructorReport!.totalRevenue.toStringAsFixed(2)} KM',
                                    color: AppTheme.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Container(
                                  decoration: AppTheme.cardDecoration,
                                  child: DataTable2(
                                    columnSpacing: 16,
                                    horizontalMargin: 20,
                                    minWidth: 600,
                                    headingRowHeight: 52,
                                    dataRowHeight: 52,
                                    columns: const [
                                      DataColumn2(
                                          label: Text('Instruktor'),
                                          size: ColumnSize.L),
                                      DataColumn2(
                                          label: Text('Kursevi'),
                                          numeric: true),
                                      DataColumn2(
                                          label: Text('Studenti'),
                                          numeric: true),
                                      DataColumn2(
                                          label: Text('Prihod (KM)'),
                                          numeric: true),
                                      DataColumn2(
                                          label: Text('Ocjena'),
                                          numeric: true),
                                    ],
                                    rows: provider
                                        .instructorReport!.instructors
                                        .map((i) => DataRow2(cells: [
                                              DataCell(Text(
                                                i.instructorName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )),
                                              DataCell(Text(
                                                  i.coursesCount
                                                      .toString())),
                                              DataCell(Text(
                                                  i.totalStudents
                                                      .toString())),
                                              DataCell(Text(i.totalRevenue
                                                  .toStringAsFixed(2))),
                                              DataCell(Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const Icon(
                                                      Icons.star_rounded,
                                                      color:
                                                          Color(0xFFFF9800),
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
                              ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
