import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import 'admin_sidebar.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/course/course_list_screen.dart';
import '../screens/user/user_management_screen.dart';
import '../screens/instructor/instructor_management_screen.dart';
import '../screens/reservation/reservation_management_screen.dart';
import '../screens/review/review_management_screen.dart';
import '../screens/notification/notification_management_screen.dart';
import '../screens/report/report_generation_screen.dart';
import '../screens/category/category_management_screen.dart';

class AdminLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminLayout({super.key, required this.onLogout});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  String _userName = 'Admin';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        // Decode JWT payload to extract user info.
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final claims = jsonDecode(decoded) as Map<String, dynamic>;
          final user = UserInfo.fromClaims(claims);
          if (mounted) {
            setState(() {
              _userName = user.fullName.trim().isNotEmpty
                  ? user.fullName
                  : 'Admin';
              _userEmail = user.email;
            });
          }
        }
      }
    } catch (_) {
      // Silently ignore decode errors.
    }
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const CourseListScreen();
      case 2:
        return const UserManagementScreen();
      case 3:
        return const InstructorManagementScreen();
      case 4:
        return const ReservationManagementScreen();
      case 5:
        return const ReviewManagementScreen();
      case 6:
        return const NotificationManagementScreen();
      case 7:
        return const ReportGenerationScreen();
      case 8:
        return const CategoryManagementScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) =>
                setState(() => _selectedIndex = index),
            onLogout: widget.onLogout,
            userName: _userName,
            userEmail: _userEmail,
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
