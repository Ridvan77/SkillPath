import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../widgets/course_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      if (courseProvider.courses.isEmpty) {
        courseProvider.fetchCourses(reset: true, pageSize: 50);
      }
      context.read<CategoryProvider>().fetchCategories();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final cp = context.read<CourseProvider>();
      if (!cp.isLoading && cp.hasNextPage) {
        cp.nextPage();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        onApply: () {
          Navigator.pop(context);
          context.read<CourseProvider>().fetchCourses(reset: true, pageSize: 50);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kursevi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Consumer<CourseProvider>(
                    builder: (_, cp, __) {
                      final hasFilters = cp.selectedCategoryId != null ||
                          cp.selectedDifficulty != null;
                      return hasFilters
                          ? TextButton(
                              onPressed: () {
                                cp.clearFilters();
                                _searchController.clear();
                                cp.fetchCourses(reset: true, pageSize: 50);
                              },
                              child: const Text('Ocisti'),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // ---- Search Bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pretrazi kurseve ili predavace...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.tune, size: 20, color: Colors.grey.shade700),
                    onPressed: _showFilterSheet,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF3F51B5)),
                  ),
                ),
                onSubmitted: (_) {
                  context.read<CourseProvider>()
                    ..setSearchQuery(_searchController.text.trim())
                    ..fetchCourses(reset: true, pageSize: 50);
                },
              ),
            ),

            const SizedBox(height: 12),

            // ---- Course List ----
            Expanded(
              child: Consumer<CourseProvider>(
                builder: (context, courseProvider, _) {
                  if (courseProvider.isLoading && courseProvider.filteredCourses.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (courseProvider.filteredCourses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Nema pronadjenih kurseva',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => courseProvider.fetchCourses(reset: true, pageSize: 50),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: courseProvider.filteredCourses.length +
                          (courseProvider.hasNextPage ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == courseProvider.filteredCourses.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final course = courseProvider.filteredCourses[index];
                        return CourseCard(
                          courseId: course.id,
                          title: course.title,
                          instructorName: course.instructorName,
                          price: course.price,
                          imageUrl: course.imageUrl,
                          averageRating: course.averageRating,
                          reviewCount: course.reviewCount,
                          difficultyLevel: course.difficultyLevel,
                          categoryName: course.categoryName,
                          durationWeeks: course.durationWeeks,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(courseId: course.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5B5FC7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF5B5FC7) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
