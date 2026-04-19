import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/dashboard_tab.dart';
import '../booking/bookings_screen.dart';
import '../plant/plant_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _index = 0;

  final _screens = const [
    DashboardTab(),
    BookingsScreen(),
    PlantScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
    _NavItem(icon: Icons.local_florist_outlined, activeIcon: Icons.local_florist_rounded, label: 'Plants'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: _index,
        items: _items,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  const _PremiumNavBar({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppTheme.primary : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.3, end: 0),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
