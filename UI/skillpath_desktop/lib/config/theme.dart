import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // -- Brand colors ----------------------------------------------------------
  static const Color primary = Colors.indigo;
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color sidebarBackground = Color(0xFF1B2A4A);
  static const Color sidebarText = Color(0xFFCFD8DC);
  static const Color sidebarActiveItem = Color(0xFF3949AB);
  static const Color contentBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // -- Text styles -----------------------------------------------------------
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF212121),
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF212121),
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF212121),
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Color(0xFF424242),
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: Color(0xFF757575),
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF212121),
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF757575),
  );

  // -- ThemeData -------------------------------------------------------------
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: contentBackground,
        cardTheme: const CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cardBackground,
          foregroundColor: Color(0xFF212121),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(color: primary),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: error),
          ),
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(Colors.indigo),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
          dataTextStyle: const TextStyle(
            color: Color(0xFF616161),
            fontSize: 14,
          ),
          dividerThickness: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE8EAF6),
          labelStyle: const TextStyle(fontSize: 12, color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: headingSmall,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0),
          thickness: 1,
          space: 1,
        ),
      );

  // -- Helpers ---------------------------------------------------------------

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      );

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'completed':
        return success;
      case 'pending':
        return warning;
      case 'cancelled':
      case 'inactive':
        return error;
      default:
        return info;
    }
  }
}
