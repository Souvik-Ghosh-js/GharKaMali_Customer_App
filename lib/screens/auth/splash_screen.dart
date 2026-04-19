import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      // Check if a location has been chosen; if not, ask for it
      final loc = context.read<LocationProvider>();
      if (!loc.hasLocation) {
        // Try silent GPS detect first
        await loc.detectAndSetLocation();
      }
      if (!mounted) return;
      if (!loc.hasLocation) {
        // No location yet → send to location picker before home
        final picked = await Navigator.pushReplacementNamed(
            context, '/location-picker');
        if (picked == null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28)),
                    child: const Center(
                        child: Text('🌿',
                            style: TextStyle(fontSize: 52))),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ghar Ka Mali',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Your Garden, Our Care',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16)),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2),
                ],
              ),
            ),
          ),
        ),
      );
}
