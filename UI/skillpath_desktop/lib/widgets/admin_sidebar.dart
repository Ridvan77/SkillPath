import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Navigation destination for the admin sidebar.
class SidebarItem {
  final String label;
  final IconData icon;
  final int index;
  final List<SidebarItem>? children;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.index,
    this.children,
  });
}

class AdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  static const List<SidebarItem> _topLevelItems = [
    SidebarItem(label: 'Dashboard', icon: Icons.dashboard_rounded, index: 0),
    SidebarItem(label: 'Kursevi', icon: Icons.school_rounded, index: 1),
    SidebarItem(
        label: 'Korisnici', icon: Icons.people_alt_rounded, index: 2),
    SidebarItem(
        label: 'Predavači', icon: Icons.person_search_rounded, index: 3),
    SidebarItem(
        label: 'Rezervacije', icon: Icons.event_note_rounded, index: 4),
    SidebarItem(
        label: 'Recenzije', icon: Icons.rate_review_rounded, index: 5),
    SidebarItem(
        label: 'Obavjestenja',
        icon: Icons.notifications_active_rounded,
        index: 6),
    SidebarItem(
        label: 'Izvještaji', icon: Icons.assessment_rounded, index: 7),
  ];

  static const SidebarItem _categoriesItem = SidebarItem(
      label: 'Kategorije', icon: Icons.category_rounded, index: 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppTheme.sidebarBackground,
      child: Column(
        children: [
          // ---- Branding ----------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SkillPath',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Color(0xFF90A4AE),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(
            color: Color(0xFF2A3F5F),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 12),

          // ---- Navigation items --------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Top-level items
                for (final item in _topLevelItems) _buildNavItem(item),

                // Categories
                _buildNavItem(_categoriesItem),
              ],
            ),
          ),

          // ---- User info + logout ------------------------------------------
          const Divider(
            color: Color(0xFF2A3F5F),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Color(0xFF90A4AE),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFF90A4AE), size: 20),
                  tooltip: 'Odjavi se',
                  onPressed: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item) {
    final isSelected = widget.selectedIndex == item.index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? AppTheme.sidebarActiveItem.withValues(alpha: 0.8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppTheme.sidebarActiveItem.withValues(alpha: 0.3),
          onTap: () => widget.onItemSelected(item.index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.sidebarText,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.sidebarText,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
