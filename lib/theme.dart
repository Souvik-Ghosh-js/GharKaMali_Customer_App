import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary gradient colors (teal-blue)
  static const Color primaryStart = Color.fromARGB(255, 0, 122, 255); // HSL(210,70%,55%)
  static const Color primaryEnd = Color.fromARGB(255, 70, 150, 255); // lighter variant

  // Dark mode background
  static const Color darkBackground = Color.fromARGB(255, 30, 30, 45);

  // Card background with glassmorphism effect (semi‑transparent)
  static const Color cardBackground = Color.fromARGB(150, 255, 255, 255);

  // Status chip colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // Text theme using Inter
  static TextTheme textTheme = TextTheme(
    headline1: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
    headline2: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black),
    bodyText1: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    bodyText2: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
    button: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryStart,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    textTheme: textTheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryStart,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    textTheme: textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// ---------- Custom Widgets ----------

class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  const RoundedCard({Key? key, required this.child, this.padding, this.margin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        // optional blur for glass effect – requires BackdropFilter in parent if needed
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  const GradientButton({Key? key, required this.label, required this.onPressed, this.isLoading = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primaryStart, AppTheme.primaryEnd]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: AppTheme.textTheme.button),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({Key? key, required this.label, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// Simple fade‑in animation wrapper
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  const FadeIn({Key? key, required this.child, this.duration = const Duration(milliseconds: 400)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, _) => Opacity(opacity: value, child: child),
    );
  }
}
