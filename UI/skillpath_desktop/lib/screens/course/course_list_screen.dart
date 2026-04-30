import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../providers/course_management_provider.dart';
import '../../widgets/loading_widget.dart';
import 'course_form_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _searchController = TextEditingController();
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseManagementProvider>();
      provider.fetchCourses(page: 1);
      provider.fetchDropdownData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context
        .read<CourseManagementProvider>()
        .fetchCourses(page: 1, search: _searchController.text.trim());
  }

  void _openForm({Map<String, dynamic>? existingCourse}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(existingCourse: existingCourse),
      ),
    );
  }

  Future<void> _deleteCourse(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da zelite obrisati kurs "$title"?'),
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
          await context.read<CourseManagementProvider>().deleteCourse(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kurs uspjesno obrisan')),
        );
      }
    }
  }

  static int _difficultyOrder(String level) {
    final l = level.toLowerCase();
    if (l.contains('pocet') || l.contains('počet') || l == 'beginner') return 0;
    if (l.contains('sredn') || l == 'intermediate') return 1;
    if (l.contains('napred') || l == 'advanced') return 2;
    return 3;
  }

  List<CourseDto> _sortedCourses(List<CourseDto> courses) {
    final sorted = List<CourseDto>.from(courses);
    sorted.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0: // Kurs
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 1: // Predavač
          result = a.instructorName
              .toLowerCase()
              .compareTo(b.instructorName.toLowerCase());
          break;
        case 2: // Kategorija
          result = a.categoryName
              .toLowerCase()
              .compareTo(b.categoryName.toLowerCase());
          break;
        case 3: // Cijena
          result = a.price.compareTo(b.price);
          break;
        case 4: // Ocjena
          result = a.averageRating.compareTo(b.averageRating);
          break;
        case 5: // Nivo
          result = _difficultyOrder(a.difficultyLevel)
              .compareTo(_difficultyOrder(b.difficultyLevel));
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  void _viewCourseDetails(CourseDto course) {
    showDialog(
      context: context,
      builder: (ctx) => _CourseDetailDialog(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseManagementProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upravljanje Kursevima',
                          style: AppTheme.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Pregled i upravljanje svim kursevima u sistemu',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Dodaj Kurs'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search bar + category filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pretraži kurseve po nazivu ili predavaču...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: provider.categoryFilter,
                        hint: const Text('Svi'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Svi'),
                          ),
                          ...provider.categories.map((cat) {
                            final id = cat['id'] as int? ??
                                cat['categoryId'] as int? ??
                                0;
                            final name = cat['name'] as String? ??
                                cat['categoryName'] as String? ??
                                '';
                            return DropdownMenuItem<int?>(
                              value: id,
                              child: Text(name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            provider.clearCategoryFilter();
                          } else {
                            provider.fetchCourses(
                                page: 1, categoryId: value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data table
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: AppTheme.cardDecoration,
                    child: provider.isLoading
                      ? const LoadingWidget()
                      : provider.courses.isEmpty
                          ? const Center(
                              child: Text('Nema kurseva za prikaz',
                                  style: AppTheme.bodySmall))
                          : Column(
                              children: [
                                Expanded(
                                  child: DataTable2(
                                    columnSpacing: 16,
                                    horizontalMargin: 20,
                                    minWidth: 900,
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _sortAscending,
                                    headingRowHeight: 52,
                                    dataRowHeight: 68,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    columns: [
                                      DataColumn2(
                                        label: const Text('Kurs'),
                                        size: ColumnSize.L,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      DataColumn2(
                                        label: const Text('Predavač'),
                                        size: ColumnSize.M,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      DataColumn2(
                                        label: const Text('Kategorija'),
                                        size: ColumnSize.S,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      DataColumn2(
                                        label: const Text('Cijena'),
                                        size: ColumnSize.S,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      DataColumn2(
                                        label: const Text('Ocjena'),
                                        size: ColumnSize.S,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      DataColumn2(
                                        label: const Text('Nivo'),
                                        size: ColumnSize.S,
                                        onSort: (i, asc) => setState(() {
                                          _sortColumnIndex = i;
                                          _sortAscending = asc;
                                        }),
                                      ),
                                      const DataColumn2(
                                        label: Text('Akcije'),
                                        size: ColumnSize.S,
                                        fixedWidth: 140,
                                      ),
                                    ],
                                    rows: _sortedCourses(provider.courses)
                                        .map((course) {
                                      return DataRow2(
                                        cells: [
                                          // Title with image and duration
                                          DataCell(
                                            Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: course.imageUrl !=
                                                              null &&
                                                          course.imageUrl!
                                                              .isNotEmpty
                                                      ? Image.network(
                                                          course.imageUrl!,
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __,
                                                                  ___) =>
                                                              Container(
                                                            width: 44,
                                                            height: 44,
                                                            color: Colors
                                                                .grey[200],
                                                            child: const Icon(
                                                                Icons.image,
                                                                size: 20),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 44,
                                                          height: 44,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                              Icons.school,
                                                              size: 20),
                                                        ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        course.title,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        '${course.durationWeeks} sedmica',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Predavač
                                          DataCell(
                                              Text(course.instructorName)),
                                          // Kategorija badge
                                          DataCell(
                                            _CategoryBadge(
                                                name: course.categoryName),
                                          ),
                                          // Cijena
                                          DataCell(Text(
                                            '${course.price.toStringAsFixed(2)} KM',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )),
                                          // Ocjena with review count
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.star_rounded,
                                                    color: Color(0xFFFF9800),
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${course.averageRating.toStringAsFixed(1)} (${course.reviewCount})',
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Nivo (difficulty level)
                                          DataCell(
                                            _DifficultyBadge(
                                              level: course.difficultyLevel,
                                            ),
                                          ),
                                          // Akcije: view, edit, delete
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                      Icons
                                                          .visibility_outlined,
                                                      size: 18,
                                                      color:
                                                          Colors.grey[600]),
                                                  tooltip: 'Pregled',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                  onPressed: () =>
                                                      _viewCourseDetails(
                                                          course),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                      Icons.edit_outlined,
                                                      size: 18,
                                                      color:
                                                          Colors.grey[600]),
                                                  tooltip: 'Uredi',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                  onPressed: () => _openForm(
                                                    existingCourse:
                                                        course.toJson(),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      size: 18,
                                                      color: AppTheme.error),
                                                  tooltip: 'Obrisi',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 36,
                                                    minHeight: 36,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteCourse(
                                                    course.id,
                                                    course.title,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                                // Pagination
                                if (provider.totalPages > 1)
                                  _PaginationBar(
                                    currentPage: provider.currentPage,
                                    totalPages: provider.totalPages,
                                    onPageChanged: (page) =>
                                        provider.fetchCourses(page: page),
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

class _CourseDetailDialog extends StatelessWidget {
  final CourseDto course;

  const _CourseDetailDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                children: [
                  Expanded(
                    child: Text('Detalji kursa', style: AppTheme.headingSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Course image and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: course.imageUrl != null &&
                            course.imageUrl!.isNotEmpty
                        ? Image.network(
                            course.imageUrl!,
                            width: 120,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 120,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 32),
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.school, size: 32),
                          ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.shortDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Details grid
              _detailRow('Predavač', course.instructorName),
              _detailRow('Kategorija', course.categoryName),
              _detailRow(
                  'Cijena', '${course.price.toStringAsFixed(2)} KM'),
              _detailRow(
                  'Trajanje', '${course.durationWeeks} sedmica'),
              _detailRow('Nivo',
                  _getDifficultyLabel(course.difficultyLevel)),
              _detailRow('Ocjena',
                  '${course.averageRating.toStringAsFixed(1)} (${course.reviewCount} recenzija)'),
              _detailRow(
                  'Status', course.isActive ? 'Aktivan' : 'Neaktivan'),
              _detailRow(
                  'Istaknuti', course.isFeatured ? 'Da' : 'Ne'),

              const SizedBox(height: 24),
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  static String _getDifficultyLabel(String level) {
    final lowerLevel = level.toLowerCase();
    if (lowerLevel.contains('pocet') ||
        lowerLevel.contains('počet') ||
        lowerLevel == 'beginner') {
      return 'Početni';
    } else if (lowerLevel.contains('sredn') ||
        lowerLevel == 'intermediate') {
      return 'Srednji';
    } else if (lowerLevel.contains('napred') ||
        lowerLevel == 'advanced') {
      return 'Napredni';
    }
    return level;
  }
}

class _CategoryBadge extends StatelessWidget {
  final String name;

  const _CategoryBadge({required this.name});

  static const _categoryColors = <String, Color>{
    'programiranje': Color(0xFF3B82F6),
    'marketing': Color(0xFF10B981),
    'dizajn': Color(0xFF8B5CF6),
    'biznis': Color(0xFFF59E0B),
    'fitness': Color(0xFFEF4444),
    'muzika': Color(0xFFEC4899),
    'jezici': Color(0xFF06B6D4),
  };

  @override
  Widget build(BuildContext context) {
    final color =
        _categoryColors[name.toLowerCase()] ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String level;

  const _DifficultyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final lowerLevel = level.toLowerCase();
    Color color;
    String label;

    if (lowerLevel.contains('pocet') ||
        lowerLevel.contains('počet') ||
        lowerLevel == 'beginner') {
      color = const Color(0xFF10B981);
      label = 'Početni';
    } else if (lowerLevel.contains('sredn') ||
        lowerLevel == 'intermediate') {
      color = const Color(0xFFF59E0B);
      label = 'Srednji';
    } else if (lowerLevel.contains('napred') ||
        lowerLevel == 'advanced') {
      color = const Color(0xFFEF4444);
      label = 'Napredni';
    } else {
      color = const Color(0xFF6B7280);
      label = level;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          for (int i = 1; i <= totalPages && i <= 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: i == currentPage
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onPageChanged(i),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: i == currentPage
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
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
