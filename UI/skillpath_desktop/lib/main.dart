import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';
import 'package:window_manager/window_manager.dart';

import 'config/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/course_management_provider.dart';
import 'providers/reservation_management_provider.dart';
import 'providers/notification_management_provider.dart';
import 'providers/review_management_provider.dart';
import 'providers/report_provider.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/admin_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Window configuration ------------------------------------------------
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1100, 700),
    center: true,
    title: 'SkillPath - Admin Panel',
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SkillPathDesktopApp());
}

class SkillPathDesktopApp extends StatefulWidget {
  const SkillPathDesktopApp({super.key});

  @override
  State<SkillPathDesktopApp> createState() => _SkillPathDesktopAppState();
}

class _SkillPathDesktopAppState extends State<SkillPathDesktopApp> {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();

    // Handle forced logout when token expires.
    ApiClient.onAuthenticationExpired = () {
      if (mounted) {
        setState(() => _isAuthenticated = false);
      }
    };
  }

  Future<void> _checkExistingAuth() async {
    final token = await ApiClient.getToken();
    if (mounted) {
      setState(() {
        _isAuthenticated = token != null && token.isNotEmpty;
        _isCheckingAuth = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _isAuthenticated = true);
  }

  void _onLogout() async {
    await ApiClient.clearTokens();
    if (mounted) {
      setState(() => _isAuthenticated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CourseManagementProvider()),
        ChangeNotifierProvider(create: (_) => ReservationManagementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationManagementProvider()),
        ChangeNotifierProvider(create: (_) => ReviewManagementProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'SkillPath - Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _isCheckingAuth
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : _isAuthenticated
                ? AdminLayout(onLogout: _onLogout)
                : LoginScreen(onLoginSuccess: _onLoginSuccess),
      ),
    );
  }
}
