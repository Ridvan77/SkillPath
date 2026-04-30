import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../widgets/course_card.dart';
import '../course/course_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriti'),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favProvider, _) {
          if (favProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Nemate omiljenih kurseva.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dodajte kurseve u favorite pritiskom na ikonu srca.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => favProvider.fetchFavorites(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favProvider.favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = favProvider.favorites[index];
                return Dismissible(
                  key: Key(course.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) {
                    favProvider.toggleFavorite(course.id);
                  },
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseDetailScreen(courseId: course.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
