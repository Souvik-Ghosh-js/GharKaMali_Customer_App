import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppTheme {
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF065F46); // Emerald 800
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      background: background,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: border)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 10,
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF94A3B8), // Slate 400 for better visibility than 500
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 10,
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF94A3B8),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

class GkmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool animated;
  const GkmCard({super.key, required this.child, this.padding, this.onTap, this.animated = true});

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: child,
      ),
    );

    if (animated) {
      return card
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
    }
    return card;
  }
}

class GkmBadge extends StatelessWidget {
  final String text;
  const GkmBadge(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final colors = _statusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.$2.withOpacity(0.1)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: colors.$2, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  (Color, Color) _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return (const Color(0xFFD1FAE5), const Color(0xFF059669));
      case 'active': case 'assigned': case 'in_progress': case 'en_route': case 'arrived':
        return (const Color(0xFFDBEAFE), const Color(0xFF2563EB));
      case 'cancelled': case 'failed': return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      case 'pending': return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
      default: return (const Color(0xFFF1F5F9), const Color(0xFF64748B));
    }
  }
}
