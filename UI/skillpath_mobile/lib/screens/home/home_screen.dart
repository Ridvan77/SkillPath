import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../providers/recommender_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../course/course_detail_screen.dart';
import '../course/course_list_screen.dart';
import '../reservation/my_reservations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<CategoryProvider>().fetchCategories();
    // Fetch ALL courses (use large pageSize so none are missed)
    context.read<CourseProvider>().fetchCourses(reset: true, pageSize: 50);
    context.read<RecommenderProvider>().fetchRecommendations();
    context.read<FavoritesProvider>().fetchFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCourseDetail(String courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(courseId: courseId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: CustomScrollView(
            slivers: [
              // ---- Header: Title + Moje Rezervacije ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Pregled Kurseva',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildReservationsButton(),
                    ],
                  ),
                ),
              ),

              // ---- Search Bar ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretrazi kurseve ili predavace...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.tune, size: 20, color: Colors.grey.shade700),
                        onPressed: () {
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
                        },
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
                        borderSide: const BorderSide(color: Color(0xFF5B5FC7)),
                      ),
                    ),
                    onSubmitted: (query) {
                      final cp = context.read<CourseProvider>();
                      cp.setSearchQuery(query.trim());
                      cp.fetchCourses(reset: true, pageSize: 50);
                    },
                  ),
                ),
              ),

              // ---- Svi Kursevi / Moji Favoriti Toggle ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildToggleButton(
                        label: 'Svi Kursevi',
                        isActive: !_showFavorites,
                        onTap: () => setState(() => _showFavorites = false),
                      ),
                      _buildToggleButton(
                        label: 'Moji Favoriti',
                        icon: Icons.favorite_border,
                        isActive: _showFavorites,
                        onTap: () => setState(() => _showFavorites = true),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showFavorites)
                _buildFavoritesList()
              else ...[
                // ---- Section header ----
                _buildSectionHeader(
                  icon: Icons.auto_awesome,
                  iconColor: Colors.deepPurple.shade400,
                  title: 'Personalizirane Preporuke',
                ),

                // ---- All courses in one vertical list ----
                // Recommended courses get the purple explanation tag,
                // the rest show without it. This matches the DOCX mockup.
                _buildAllCoursesList(),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- Section header builder ----
  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- All courses with recommendation tags ----
  Widget _buildAllCoursesList() {
    return Consumer2<CourseProvider, RecommenderProvider>(
      builder: (context, courseProvider, recommender, _) {
        final courses = courseProvider.filteredCourses;

        if (courseProvider.isLoading && courses.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (courses.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text('Nema dostupnih kurseva.',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // Build maps of courseId → explanation and courseId → score
        final recommendationMap = <String, String>{};
        final recommendationScores = <String, double>{};
        for (final rec in recommender.recommendations) {
          recommendationMap[rec.courseId] = rec.explanation;
          recommendationScores[rec.courseId] = rec.recommendationScore;
        }

        // Sort by recommendation score (highest first), then by date
        final sorted = List<CourseDto>.from(courses);
        sorted.sort((a, b) {
          final aScore = recommendationScores[a.id] ?? -1;
          final bScore = recommendationScores[b.id] ?? -1;
          if (aScore != bScore) return bScore.compareTo(aScore);
          return b.createdAt.compareTo(a.createdAt);
        });

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final course = sorted[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
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
                    explanation: recommendationMap[course.id],
                    onTap: () => _navigateToCourseDetail(course.id),
                  ),
                );
              },
              childCount: sorted.length,
            ),
          ),
        );
      },
    );
  }

  // ---- Recommendations (kept for reference, no longer used directly) ----
  Widget _buildRecommendationsList() {
    return Consumer<RecommenderProvider>(
      builder: (context, recommender, _) {
        final recs = recommender.recommendations;
        if (recs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Koristite aplikaciju da biste dobili personalizirane preporuke.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final rec = recs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
                    courseId: rec.courseId,
                    title: rec.title,
                    instructorName: rec.instructorName,
                    price: rec.price,
                    imageUrl: rec.imageUrl,
                    averageRating: rec.averageRating,
                    reviewCount: rec.reviewCount,
                    difficultyLevel: rec.difficultyLevel,
                    categoryName: rec.categoryName,
                    explanation: rec.explanation,
                    onTap: () => _navigateToCourseDetail(rec.courseId),
                  ),
                );
              },
              childCount: recs.length.clamp(0, 3),
            ),
          ),
        );
      },
    );
  }

  // ---- New Courses (sorted by date, most recent) ----
  Widget _buildNewCoursesList() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        // Sort courses by createdAt descending to get newest
        final allCourses = List<CourseDto>.from(courseProvider.filteredCourses);
        allCourses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final newCourses = allCourses.take(3).toList();

        if (newCourses.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: newCourses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final course = newCourses[index];
                return _buildHorizontalCourseCard(course);
              },
            ),
          ),
        );
      },
    );
  }

  // ---- Popular Categories ----
  Widget _buildPopularCategories() {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        if (catProvider.categories.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        // Sort by courses count descending
        final sorted = List<CategoryDto>.from(catProvider.categories);
        sorted.sort((a, b) => b.coursesCount.compareTo(a.coursesCount));

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = sorted[index];
                return _buildCategoryCard(cat);
              },
            ),
          ),
        );
      },
    );
  }

  // ---- Horizontal course card for "Novi Kursevi" ----
  Widget _buildHorizontalCourseCard(CourseDto course) {
    // Generate color from title
    final hash = course.title.hashCode;
    final colors = [
      [const Color(0xFF6c5ce7), const Color(0xFFa29bfe)],
      [const Color(0xFF0d7377), const Color(0xFF14ffec)],
      [const Color(0xFF0f3460), const Color(0xFF533483)],
      [const Color(0xFF2c3e50), const Color(0xFF3498db)],
      [const Color(0xFFe17055), const Color(0xFFfdcb6e)],
    ];
    final colorPair = colors[hash.abs() % colors.length];

    return GestureDetector(
      onTap: () => _navigateToCourseDetail(course.id),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colorPair,
          ),
          boxShadow: [
            BoxShadow(
              color: colorPair[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // NEW badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NOVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  course.instructorName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            course.averageRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        ],
                      ),
                    ),
                    Text(
                      '${course.price.toStringAsFixed(0)} KM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Category card ----
  Widget _buildCategoryCard(CategoryDto cat) {
    final icons = {
      'Programiranje': Icons.code,
      'Dizajn': Icons.brush,
      'Biznis': Icons.business,
      'Jezici': Icons.translate,
      'Muzika': Icons.music_note,
      'Fitness': Icons.fitness_center,
    };
    final categoryColors = {
      'Programiranje': const Color(0xFF5B5FC7),
      'Dizajn': Colors.pink,
      'Biznis': Colors.teal,
      'Jezici': Colors.orange,
      'Muzika': Colors.purple,
      'Fitness': Colors.green,
    };

    final icon = icons[cat.name] ?? Icons.category;
    final color = categoryColors[cat.name] ?? Colors.indigo;

    return GestureDetector(
      onTap: () {
        context.read<CourseProvider>().setCategoryFilter(cat.id);
        context.read<CourseProvider>().fetchCourses(reset: true, pageSize: 50);
        // Navigate to courses tab (index 1 of bottom nav)
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              cat.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${cat.coursesCount} kurseva',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Reservations pill button ----
  Widget _buildReservationsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF5B5FC7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Moje Rezervacije',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Toggle button ----
  Widget _buildToggleButton({
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5B5FC7) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF5B5FC7) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Favorites list ----
  Widget _buildFavoritesList() {
    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final favorites = favProvider.favorites;

        if (favProvider.isLoading && favorites.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (favorites.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Nemate sacuvanih favorita.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final course = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
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
                    onTap: () => _navigateToCourseDetail(course.id),
                  ),
                );
              },
              childCount: favorites.length,
            ),
          ),
        );
      },
    );
  }
}
