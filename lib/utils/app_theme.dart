import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF16a34a);
  static const Color primaryDark = Color(0xFF14532d);
  static const Color primaryLight = Color(0xFF4ade80);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, background: background, surface: surface),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'sans-serif'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
    ),
  );
}

class GkmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const GkmCard({super.key, required this.child, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: child,
    ),
  );
}

class GkmBadge extends StatelessWidget {
  final String text;
  const GkmBadge(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final colors = _statusColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: colors.$2, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
  (Color, Color) _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
      case 'active': case 'assigned': case 'in_progress': case 'en_route': case 'arrived':
        return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8));
      case 'cancelled': case 'failed': return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      case 'pending': return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
      default: return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
  }
}
