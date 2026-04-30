import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import 'services/fcm_service.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/instructor_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/recommender_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/review_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/course/course_list_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/instructor/instructor_home_screen.dart';
import 'screens/instructor/instructor_reservations_screen.dart';
import 'screens/instructor/instructor_reviews_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/reservation/my_reservations_screen.dart';

// Global Stripe keys (to avoid NotInitializedError)
String? globalStripePublishableKey;
String? globalStripeSecretKey;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Hide overflow indicators in debug mode
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) return;
    FlutterError.presentError(details);
  };

  // Load .env and initialize Stripe
  await _loadEnvAndInitStripe();

  runApp(const SkillPathApp());
}

Future<void> _loadEnvAndInitStripe() async {
  // Step 1: Load .env file
  try {
    String? envContent;
    try {
      envContent = await rootBundle.loadString('assets/.env');
      debugPrint('[MAIN] Successfully loaded .env from assets');
    } catch (assetsError) {
      debugPrint('[MAIN] Could not load .env from assets: $assetsError');
      if (assetsError.toString().contains('NotInitializedError') ||
          assetsError.runtimeType.toString().contains('NotInitialized')) {
        try {
          await dotenv.load(fileName: '.env');
          envContent = null;
          debugPrint('[MAIN] .env loaded from file system');
        } catch (_) {
          debugPrint('[MAIN] Using hardcoded fallback keys');
          globalStripePublishableKey =
              'pk_test_51TRvTA9PC2svLpdcjr9zgKUEU28hpkUW5YVVYVexgjbsCKGwXRhVNBLMQI8ryNz6nVb86E8m4yJjE41Ja1q0VRQA00lpLHJb4K';
          globalStripeSecretKey =
              'sk_test_51TRvTA9PC2svLpdcNKAXJKMNo71658kMxG0s44ctfqKKKEeD9HkoPgCGg9uuFUUYUkQXH5RiPRIpOHX3u9QG5vWx00OzNplk0y';
        }
      } else {
        rethrow;
      }
    }

    // Parse envContent if loaded from assets
    if (envContent != null) {
      final lines = envContent.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;
        final eqIndex = trimmedLine.indexOf('=');
        if (eqIndex > 0) {
          final key = trimmedLine.substring(0, eqIndex).trim();
          final value = trimmedLine.substring(eqIndex + 1).trim();
          try {
            dotenv.env[key] = value;
          } catch (_) {
            // dotenv not initialized, set globals directly
          }
          if (key == 'STRIPE_PUBLISHABLE_KEY') {
            globalStripePublishableKey = value;
          } else if (key == 'STRIPE_SECRET_KEY') {
            globalStripeSecretKey = value;
          }
        }
      }
    }

    // Ensure globals are set from dotenv if not already
    try {
      globalStripePublishableKey ??= dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      globalStripeSecretKey ??= dotenv.env['STRIPE_SECRET_KEY'];
    } catch (_) {
      // dotenv access failed, use hardcoded fallback
      globalStripePublishableKey ??=
          'pk_test_51TRvTA9PC2svLpdcjr9zgKUEU28hpkUW5YVVYVexgjbsCKGwXRhVNBLMQI8ryNz6nVb86E8m4yJjE41Ja1q0VRQA00lpLHJb4K';
      globalStripeSecretKey ??=
          'sk_test_51TRvTA9PC2svLpdcNKAXJKMNo71658kMxG0s44ctfqKKKEeD9HkoPgCGg9uuFUUYUkQXH5RiPRIpOHX3u9QG5vWx00OzNplk0y';
    }

    debugPrint('[MAIN] STRIPE_PUBLISHABLE_KEY loaded: ${globalStripePublishableKey != null}');
    debugPrint('[MAIN] STRIPE_SECRET_KEY loaded: ${globalStripeSecretKey != null}');
  } catch (e) {
    debugPrint('[MAIN] Warning: .env file not found or error loading: $e');
  }

  // Step 2: Initialize Stripe SDK (only on mobile platforms)
  if (!kIsWeb) {
    try {
      final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
      if (isDesktop) {
        debugPrint('[MAIN] Desktop platform detected - Stripe PaymentSheet not available');
        return;
      }
    } catch (_) {}

    try {
      final publishableKey = globalStripePublishableKey;
      if (publishableKey != null && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        Stripe.merchantIdentifier = 'merchant.com.skillpath';
        await Stripe.instance.applySettings();
        debugPrint('[MAIN] Stripe SDK initialized successfully');
      } else {
        debugPrint('[MAIN] Stripe publishable key not available - payments will not work');
      }
    } catch (e) {
      debugPrint('[MAIN] Stripe initialization error: $e');
    }
  }
}

class SkillPathApp extends StatelessWidget {
  const SkillPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => InstructorProvider()),
        ChangeNotifierProvider(create: (_) => RecommenderProvider()),
      ],
      child: MaterialApp(
        title: 'SkillPath',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isLoggedIn) {
          // Initialize FCM after login
          FcmService.initialize();
          return MainScreen(key: MainScreen.mainKey);
        }
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // Global key to allow switching tabs from anywhere
  static final GlobalKey<_MainScreenState> mainKey = GlobalKey<_MainScreenState>();

  static void switchToTab(int index) {
    mainKey.currentState?.switchTab(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  bool _isInstructor(BuildContext context) {
    return context.read<AuthProvider>().currentUser?.roles.contains('Instructor') ?? false;
  }

  List<Widget> _getScreens(bool isInstructor) {
    if (isInstructor) {
      return const [
        InstructorHomeScreen(),
        InstructorReservationsScreen(),
        InstructorReviewsScreen(),
        UserProfileScreen(),
      ];
    }
    return const [
      HomeScreen(),
      CourseListScreen(),
      MyReservationsScreen(),
      UserProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems(bool isInstructor) {
    if (isInstructor) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Pocetna',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Raspored',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined),
          activeIcon: Icon(Icons.rate_review),
          label: 'Recenzije',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Pocetna',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.school_outlined),
        activeIcon: Icon(Icons.school),
        label: 'Kursevi',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Rezervacije',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isInstructor = _isInstructor(context);
    final screens = _getScreens(isInstructor);
    final navItems = _getNavItems(isInstructor);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: navItems,
      ),
    );
  }
}
