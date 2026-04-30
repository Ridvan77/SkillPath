import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/loading_widget.dart';

class CategoryPopularityScreen extends StatefulWidget {
  const CategoryPopularityScreen({super.key});

  @override
  State<CategoryPopularityScreen> createState() =>
      _CategoryPopularityScreenState();
}

class _CategoryPopularityScreenState
    extends State<CategoryPopularityScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<Color> _barColors = const [
    Color(0xFF3949AB),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFFC0CA33),
    Color(0xFFD81B60),
  ];

  void _generateReport() {
    context.read<ReportProvider>().fetchCategoryReport(
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
    final data = context.read<ReportProvider>().categoryReport;
    if (data.isEmpty) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SkillPath - Popularnost kategorija',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Period: ${_fromDate != null ? DateFormat('dd.MM.yyyy').format(_fromDate!) : 'Od pocetka'} - ${_toDate != null ? DateFormat('dd.MM.yyyy').format(_toDate!) : 'Do danas'}',
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'Kategorija',
              'Kursevi',
              'Upisi',
              'Prihod (KM)',
              'Ocjena'
            ],
            data: data
                .map((c) => [
                      c.categoryName,
                      c.coursesCount.toString(),
                      c.enrollmentCount.toString(),
                      c.revenue.toStringAsFixed(2),
                      c.averageRating.toStringAsFixed(1),
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
      name:
          'category_report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final data = provider.categoryReport;

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popularnost kategorija',
                      style: AppTheme.headingLarge),
                  Row(
                    children: [
                      if (data.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 18),
                          label: const Text('Izvezi PDF'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date filter row
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Od datuma'),
                        child: Text(
                          _fromDate != null
                              ? DateFormat('dd.MM.yyyy').format(_fromDate!)
                              : 'Odaberite',
                          style: TextStyle(
                              color:
                                  _fromDate != null ? null : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Do datuma'),
                        child: Text(
                          _toDate != null
                              ? DateFormat('dd.MM.yyyy').format(_toDate!)
                              : 'Odaberite',
                          style: TextStyle(
                              color: _toDate != null ? null : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: const Text('Generiraj'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (provider.isLoading)
                const Expanded(
                    child:
                        LoadingWidget(message: 'Generisanje izvjestaja...'))
              else if (data.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Odaberite period i generirajte izvjestaj',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Chart
                SizedBox(
                  height: 280,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: data
                                .map((c) => c.enrollmentCount.toDouble())
                                .reduce((a, b) => a > b ? a : b) *
                            1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, gIdx, rod, rIdx) {
                              return BarTooltipItem(
                                '${data[group.x.toInt()].categoryName}\n${rod.toY.toInt()} upisa',
                                const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= data.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    data[value.toInt()].categoryName,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 11),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: const Color(0xFFE0E0E0),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(data.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data[i].enrollmentCount.toDouble(),
                                color: _barColors[i % _barColors.length],
                                width: 28,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Table
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
                            label: Text('Kategorija'), size: ColumnSize.L),
                        DataColumn2(
                            label: Text('Kursevi'), numeric: true),
                        DataColumn2(
                            label: Text('Upisi'), numeric: true),
                        DataColumn2(
                            label: Text('Prihod (KM)'), numeric: true),
                        DataColumn2(
                            label: Text('Ocjena'), numeric: true),
                      ],
                      rows: data
                          .map((c) => DataRow2(cells: [
                                DataCell(Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _barColors[
                                            data.indexOf(c) %
                                                _barColors.length],
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(c.categoryName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                )),
                                DataCell(
                                    Text(c.coursesCount.toString())),
                                DataCell(Text(
                                    c.enrollmentCount.toString())),
                                DataCell(Text(
                                    c.revenue.toStringAsFixed(2))),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFF9800),
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text(c.averageRating
                                        .toStringAsFixed(1)),
                                  ],
                                )),
                              ]))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
