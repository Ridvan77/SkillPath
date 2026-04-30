import 'package:flutter/material.dart';
import 'package:skillpath_mobile/screens/auth/login_screen.dart';
import 'package:skillpath_mobile/screens/auth/register_screen.dart';
import 'package:skillpath_mobile/screens/course/course_detail_screen.dart';
import 'package:skillpath_mobile/screens/course/course_list_screen.dart';
import 'package:skillpath_mobile/screens/favorites/favorites_screen.dart';
import 'package:skillpath_mobile/screens/notification/notifications_screen.dart';
import 'package:skillpath_mobile/screens/profile/user_profile_screen.dart';
import 'package:skillpath_mobile/screens/reservation/my_reservations_screen.dart';
import 'package:skillpath_mobile/screens/review/write_review_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String courseList = '/courses';
  static const String courseDetail = '/courses/detail';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String myReservations = '/reservations';
  static const String writeReview = '/review/write';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        courseList: (_) => const CourseListScreen(),
        favorites: (_) => const FavoritesScreen(),
        notifications: (_) => const NotificationsScreen(),
        profile: (_) => const UserProfileScreen(),
        myReservations: (_) => const MyReservationsScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case courseDetail:
        final courseId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: courseId),
        );
      case writeReview:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => WriteReviewScreen(
            courseId: args['courseId'] as String,
            courseName: args['courseName'] as String,
          ),
        );
      default:
        return null;
    }
  }
}
