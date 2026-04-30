import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/review_management_provider.dart';
import '../../widgets/loading_widget.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() =>
      _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewManagementProvider>().fetchReviews(page: 1);
    });
  }

  Future<void> _deleteReview(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content:
            const Text('Da li ste sigurni da zelite obrisati ovu recenziju?'),
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

    if (confirmed == true && mounted) {
      final success =
          await context.read<ReviewManagementProvider>().deleteReview(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recenzija obrisana')),
        );
      }
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFF9800),
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewManagementProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upravljanje recenzijama',
                      style: AppTheme.headingLarge),
                  OutlinedButton.icon(
                    onPressed: () =>
                        provider.fetchReviews(page: 1),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Osvjezi'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                    label: 'Ukupno',
                    value: provider.totalCount.toString(),
                    color: AppTheme.primary,
                    icon: Icons.rate_review_rounded,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    label: 'Vidljive',
                    value: provider.visibleCount.toString(),
                    color: AppTheme.success,
                    icon: Icons.visibility_rounded,
                  ),
                  const SizedBox(width: 16),
                  _SummaryCard(
                    label: 'Skrivene',
                    value: provider.hiddenCount.toString(),
                    color: AppTheme.warning,
                    icon: Icons.visibility_off_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Table
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: provider.isLoading
                      ? const LoadingWidget()
                      : provider.reviews.isEmpty
                          ? const Center(
                              child: Text('Nema recenzija za prikaz',
                                  style: AppTheme.bodySmall))
                          : Column(
                              children: [
                                Expanded(
                                  child: DataTable2(
                                    columnSpacing: 12,
                                    horizontalMargin: 16,
                                    minWidth: 900,
                                    headingRowHeight: 52,
                                    dataRowHeight: 64,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    columns: const [
                                      DataColumn2(
                                          label: Text('Student'),
                                          size: ColumnSize.M),
                                      DataColumn2(
                                          label: Text('Ocjena'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Komentar'),
                                          size: ColumnSize.L),
                                      DataColumn2(
                                          label: Text('Korisno'),
                                          size: ColumnSize.S,
                                          numeric: true),
                                      DataColumn2(
                                          label: Text('Status'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Datum'),
                                          size: ColumnSize.S),
                                      DataColumn2(
                                          label: Text('Akcije'),
                                          fixedWidth: 110),
                                    ],
                                    rows: provider.reviews.map((review) {
                                      return DataRow2(
                                        color: review.isVisible
                                            ? null
                                            : WidgetStateProperty.all(
                                                AppTheme.warning
                                                    .withValues(alpha: 0.05)),
                                        cells: [
                                          DataCell(Text(
                                            review.userFullName,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w500),
                                          )),
                                          DataCell(
                                              _buildStars(review.rating)),
                                          DataCell(
                                            Text(
                                              review.comment,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.thumb_up_rounded,
                                                  size: 14,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(review.helpfulCount
                                                  .toString()),
                                            ],
                                          )),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: review.isVisible
                                                    ? AppTheme.success
                                                        .withValues(alpha: 0.1)
                                                    : AppTheme.warning
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Text(
                                                review.isVisible
                                                    ? 'Vidljiva'
                                                    : 'Skrivena',
                                                style: TextStyle(
                                                  color: review.isVisible
                                                      ? AppTheme.success
                                                      : AppTheme.warning,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(
                                            DateFormat('dd.MM.yyyy')
                                                .format(review.createdAt),
                                            style: AppTheme.bodySmall,
                                          )),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (review.isVisible)
                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .visibility_off_rounded,
                                                    size: 18,
                                                    color: AppTheme.warning,
                                                  ),
                                                  tooltip: 'Sakrij',
                                                  onPressed: () => provider
                                                      .toggleVisibility(
                                                          review.id),
                                                )
                                              else
                                                IconButton(
                                                  icon: Icon(
                                                    Icons
                                                        .visibility_rounded,
                                                    size: 18,
                                                    color: AppTheme.success,
                                                  ),
                                                  tooltip: 'Vrati na vidljivo',
                                                  onPressed: () => provider
                                                      .toggleVisibility(
                                                          review.id),
                                                ),
                                              IconButton(
                                                icon: Icon(
                                                    Icons.delete_rounded,
                                                    size: 18,
                                                    color: AppTheme.error),
                                                tooltip: 'Obrisi',
                                                onPressed: () =>
                                                    _deleteReview(
                                                        review.id),
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (provider.totalPages > 1)
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
                                          onPressed: provider.currentPage >
                                                  1
                                              ? () =>
                                                  provider.fetchReviews(
                                                      page: provider
                                                              .currentPage -
                                                          1)
                                              : null,
                                        ),
                                        Text(
                                          'Stranica ${provider.currentPage} od ${provider.totalPages}',
                                          style: AppTheme.bodySmall,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons
                                                  .chevron_right_rounded),
                                          onPressed: provider.currentPage <
                                                  provider.totalPages
                                              ? () =>
                                                  provider.fetchReviews(
                                                      page: provider
                                                              .currentPage +
                                                          1)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
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
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
                Text(label, style: AppTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
