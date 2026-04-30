import 'package:skillpath_shared/skillpath_shared.dart';

/// Simple service that calls the recommender track-view endpoint.
///
/// Used to track course views for generating personalized recommendations.
class CourseTrackingService {
  CourseTrackingService._();

  /// Tracks that the current user viewed the course with [courseId].
  ///
  /// This is a fire-and-forget operation -- failures are silently ignored
  /// to avoid disrupting the user experience.
  static Future<void> trackView(String courseId) async {
    try {
      await ApiClient.post('/api/recommender/track-view', {
        'courseId': courseId,
      });
    } catch (_) {
      // Silent fail - tracking should not interrupt UX
    }
  }
}
