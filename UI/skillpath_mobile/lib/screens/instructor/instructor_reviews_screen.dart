import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../providers/instructor_provider.dart';

class _CourseReviews {
  final String courseId;
  final String courseTitle;
  final List<ReviewDto> reviews;
  final double averageRating;
  final int totalCount;

  _CourseReviews({
    required this.courseId,
    required this.courseTitle,
    required this.reviews,
    required this.averageRating,
    required this.totalCount,
  });
}

class InstructorReviewsScreen extends StatefulWidget {
  const InstructorReviewsScreen({super.key});

  @override
  State<InstructorReviewsScreen> createState() =>
      _InstructorReviewsScreenState();
}

class _InstructorReviewsScreenState extends State<InstructorReviewsScreen> {
  List<_CourseReviews> _allCourseReviews = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    final provider = context.read<InstructorProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;

    // Ensure courses are loaded
    if (provider.courses.isEmpty && userId != null) {
      await provider.fetchInstructorCourses(userId);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final courseReviews = <_CourseReviews>[];

    for (final course in provider.courses) {
      try {
        final response =
            await ApiClient.get('/api/Review/course/${course.id}');

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final avgRating =
              (json['averageRating'] as num?)?.toDouble() ?? 0.0;
          final totalCount = json['totalCount'] as int? ?? 0;

          final reviewsJson = json['reviews'] as Map<String, dynamic>?;
          List<ReviewDto> reviews = [];
          if (reviewsJson != null) {
            final pagedResult =
                PagedResult.fromJson(reviewsJson, ReviewDto.fromJson);
            reviews = pagedResult.items;
          }

          if (reviews.isNotEmpty) {
            courseReviews.add(_CourseReviews(
              courseId: course.id,
              courseTitle: course.title,
              reviews: reviews,
              averageRating: avgRating,
              totalCount: totalCount,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error fetching reviews for ${course.id}: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _allCourseReviews = courseReviews;
      _isLoading = false;
      if (courseReviews.isEmpty && provider.courses.isNotEmpty) {
        _error = null; // no error, just no reviews
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Recenzije'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Pokusaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (_allCourseReviews.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Nema recenzija za vase kurseve.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Build a flat list of items: course headers + reviews
    final items = <dynamic>[];
    for (final courseReview in _allCourseReviews) {
      items.add(courseReview); // header
      for (final review in courseReview.reviews) {
        items.add(review); // review item
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _CourseReviews) {
          return _buildCourseHeader(item);
        } else if (item is ReviewDto) {
          return _buildReviewCard(item);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCourseHeader(_CourseReviews courseReview) {
    return Padding(
      padding: EdgeInsets.only(
        top: _allCourseReviews.first == courseReview ? 0 : 16,
        bottom: 12,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseReview.courseTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${courseReview.totalCount} recenzija',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    courseReview.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  Widget _buildReviewCard(ReviewDto review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + date
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.indigo.shade100,
                child: Text(
                  review.userFullName.isNotEmpty
                      ? review.userFullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy').format(review.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Helpful count
              if (review.helpfulCount > 0) ...[
                Icon(Icons.thumb_up_alt_outlined,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${review.helpfulCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Stars
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: i < review.rating ? Colors.amber : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(height: 8),

          // Comment
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
