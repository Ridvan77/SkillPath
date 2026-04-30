import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../providers/recommender_provider.dart';
import '../../providers/review_provider.dart';
import '../reservation/reservation_step1_screen.dart';
import '../review/write_review_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String? _selectedScheduleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourseDetail(widget.courseId);
      context.read<ReviewProvider>().fetchCourseReviews(widget.courseId);
      context.read<ReviewProvider>().canReview(widget.courseId);
      context.read<RecommenderProvider>().trackCourseView(widget.courseId);
    });
  }

  String _formatPrice(double price) {
    return '${NumberFormat("#,##0.00", "bs_BA").format(price)} KM';
  }

  String _difficultyLabel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return 'Pocetni';
      case 'intermediate': return 'Srednji';
      case 'advanced': return 'Napredni';
      default: return level;
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStars(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: Colors.amber);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          if (courseProvider.isLoading && courseProvider.selectedCourse == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final course = courseProvider.selectedCourse;
          if (course == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(courseProvider.errorMessage ?? 'Kurs nije pronadjen.'),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ---- Hero Image ----
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFav = favProvider.isFavorite(course.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => favProvider.toggleFavorite(course.id),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroImage(course),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Title & Price ----
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatPrice(course.price),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B5FC7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ---- Meta Info Row ----
                        Row(
                          children: [
                            _buildStars(course.averageRating, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${course.averageRating.toStringAsFixed(1)} (${course.reviewCount})',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${course.durationWeeks} sedmica',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ---- Chips ----
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChip(
                              _difficultyLabel(course.difficultyLevel),
                              _difficultyColor(course.difficultyLevel),
                            ),
                            _buildChip(course.categoryName, const Color(0xFF5B5FC7)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ---- Instructor ----
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF5B5FC7).withOpacity(0.1),
                        child: const Icon(Icons.person, color: Color(0xFF5B5FC7), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.instructorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Instruktor - ${course.categoryName}',
                              style: TextStyle(color: const Color(0xFF5B5FC7), fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _instructorBio(course.instructorName, course.categoryName),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ---- Description ----
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opis kursa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ---- Schedules ----
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dostupni termini',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (course.schedules.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Nema dostupnih termina.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      else
                        ...course.schedules
                            .where((s) => s.isActive)
                            .map((s) => _buildScheduleCard(s)),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ---- Reviews ----
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: _buildReviewsSection(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),

      // ---- Bottom Reserve Button ----
      bottomSheet: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          final course = courseProvider.selectedCourse;
          if (course == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B5FC7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: _selectedScheduleId == null
                      ? null
                      : () {
                          final schedule = course.schedules
                              .firstWhere((s) => s.id == _selectedScheduleId);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReservationStep1Screen(
                                course: course,
                                schedule: schedule,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    _selectedScheduleId == null
                        ? 'Odaberite termin za rezervaciju'
                        : 'Rezervisi - ${_formatPrice(course.price)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroImage(CourseDetailDto course) {
    if (course.imageUrl != null && course.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: course.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholderImage(course.title),
        errorWidget: (_, __, ___) => _buildPlaceholderImage(course.title),
      );
    }
    return _buildPlaceholderImage(course.title);
  }

  Widget _buildPlaceholderImage(String title) {
    final hash = title.hashCode;
    final colors = [
      [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
      [const Color(0xFF0f3460), const Color(0xFF533483)],
      [const Color(0xFF2c3e50), const Color(0xFF3498db)],
    ];
    final pair = colors[hash.abs() % colors.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pair,
        ),
      ),
      child: Center(
        child: Icon(Icons.school_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(CourseScheduleDto schedule) {
    final isSelected = _selectedScheduleId == schedule.id;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final isFull = schedule.isFull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: isFull ? null : () => setState(() => _selectedScheduleId = schedule.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isFull ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B5FC7)
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5B5FC7) : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF5B5FC7) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${schedule.dayOfWeek} ${schedule.startTime} - ${schedule.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(schedule.startDate)} - ${dateFormat.format(schedule.endDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.red.shade50
                      : schedule.availableSpots <= 3
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFull ? 'Popunjeno' : '${schedule.availableSpots} mjesta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFull
                        ? Colors.red.shade700
                        : schedule.availableSpots <= 3
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recenzije Polaznika',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (reviewProvider.canUserReview)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Napisi'),
                    onPressed: () {
                      final course = context.read<CourseProvider>().selectedCourse;
                      if (course != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WriteReviewScreen(
                              courseId: course.id,
                              courseName: course.title,
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (reviewProvider.errorMessage != null)
              Text(
                reviewProvider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),

            if (reviewProvider.isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),

            if (reviewProvider.totalReviewCount > 0) ...[
              // ---- Rating Overview ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big rating number
                  Column(
                    children: [
                      Text(
                        reviewProvider.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      _buildStars(reviewProvider.averageRating, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        '${reviewProvider.totalReviewCount} recenzija',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Rating distribution bars
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final star = 5 - index;
                        final count = reviewProvider.ratingDistribution[star] ?? 0;
                        final total = reviewProvider.totalReviewCount;
                        final pct = total > 0 ? count / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$star', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation(Colors.amber),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$count',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Individual Reviews ----
              ...reviewProvider.courseReviews.map((review) => _buildReviewItem(review)),
            ] else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nema recenzija za ovaj kurs.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(ReviewDto review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF5B5FC7).withOpacity(0.15),
                  child: Text(
                    review.userFullName.isNotEmpty
                        ? review.userFullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B5FC7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userFullName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        _formatTimeAgo(review.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                _buildStars(review.rating.toDouble(), size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.read<ReviewProvider>().toggleHelpful(review.id),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    review.isHelpfulByCurrentUser ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 16,
                    color: review.isHelpfulByCurrentUser
                        ? const Color(0xFF5B5FC7)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Korisno (${review.helpfulCount})',
                    style: TextStyle(
                      fontSize: 12,
                      color: review.isHelpfulByCurrentUser
                          ? const Color(0xFF5B5FC7)
                          : Colors.grey.shade600,
                      fontWeight: review.isHelpfulByCurrentUser
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _instructorBio(String name, String category) {
    final firstName = name.split(' ').first;
    final bios = {
      'Programiranje': '$firstName je iskusan softverski inzenjer sa visegodisnjim iskustvom u razvoju web i mobilnih aplikacija. Specijaliziran za moderne tehnologije i best practices u industriji.',
      'Dizajn': '$firstName je kreativni dizajner sa strasti za vizuelnu komunikaciju. Posjeduje bogato iskustvo u kreiranju korisnickih interfejsa i brendiranju.',
      'Biznis': '$firstName je poslovni konsultant sa iskustvom u upravljanju projektima i digitalnom marketingu. Posvecen prenosenju prakticnih poslovnih vjestina.',
      'Jezici': '$firstName je certificirani predavac stranih jezika sa dugogodisnjim iskustvom u poducavanju. Fokusiran na interaktivne metode ucenja.',
      'Muzika': '$firstName je profesionalni muzicar i pedagog sa iskustvom u muzickoj produkciji i edukaciji. Inspirise studente kroz prakticne projekte.',
      'Fitness': '$firstName je certificirani fitness trener sa iskustvom u personalnom treningu i grupnim programima. Posvecen zdravom zivotnom stilu.',
    };
    return bios[category] ?? '$firstName je iskusan predavac sa visegodisnjim iskustvom u svojoj oblasti. Posvecen kvalitetnoj edukaciji i uspjehu studenata.';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 30) return DateFormat('dd.MM.yyyy').format(dateTime);
    if (diff.inDays > 0) return 'prije ${diff.inDays} dana';
    if (diff.inHours > 0) return 'prije ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'prije ${diff.inMinutes} min';
    return 'upravo';
  }
}
