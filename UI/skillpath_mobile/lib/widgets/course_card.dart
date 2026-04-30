import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class CourseCard extends StatelessWidget {
  final String courseId;
  final String title;
  final String instructorName;
  final double price;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final String difficultyLevel;
  final String? categoryName;
  final int durationWeeks;
  final String? explanation;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.courseId,
    required this.title,
    required this.instructorName,
    required this.price,
    this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.difficultyLevel,
    this.categoryName,
    this.durationWeeks = 0,
    this.explanation,
    this.onTap,
  });

  String _difficultyLabel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Pocetni';
      case 'intermediate':
        return 'Srednji';
      case 'advanced':
        return 'Napredni';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Image with Heart Overlay ----
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _buildImage(),
                ),
                // Heart button — isolated Consumer to avoid parent rebuild
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favProvider, _) {
                      final isFav = favProvider.isFavorite(courseId);
                      return GestureDetector(
                        onTap: () {
                          favProvider.toggleFavorite(courseId);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ---- Content ----
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${NumberFormat("#,##0.00", "bs_BA").format(price)} KM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF5B5FC7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Instructor
                  Text(
                    instructorName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Rating + Duration row
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' ($reviewCount)',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      if (durationWeeks > 0) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          '$durationWeeks sedmica',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Difficulty + Category chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(_difficultyLabel(difficultyLevel)),
                      if (categoryName != null) _buildChip(categoryName!),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Recommendation Explanation ----
            if (explanation != null && explanation!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.deepPurple.shade100, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation!,
                        style: TextStyle(
                          color: Colors.deepPurple.shade700,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholderImage(),
        errorWidget: (_, __, ___) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    // Generate a consistent color from the title
    final hash = title.hashCode;
    final colors = [
      [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
      [const Color(0xFF0f3460), const Color(0xFF533483)],
      [const Color(0xFF2c3e50), const Color(0xFF3498db)],
      [const Color(0xFF1b1b2f), const Color(0xFF162447)],
      [const Color(0xFF0d7377), const Color(0xFF14ffec)],
      [const Color(0xFF6c5ce7), const Color(0xFFa29bfe)],
    ];
    final colorPair = colors[hash.abs() % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_outlined,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
