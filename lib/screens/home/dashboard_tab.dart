import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';
import '../../theme.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List _bookings = [];
  List _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    try {
      final results = await Future.wait([
        api.getMyBookings(status: 'assigned,in_progress,pending', page: 1),
        api.getPlans(),
      ]);
      setState(() {
        _bookings = results[0]['data']['bookings'] ?? [];
        _plans = results[1]['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final loc = context.watch<LocationProvider>();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Hello, ${user?['name']?.split(' ')[0] ?? 'there'} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              'Let\'s make your garden thrive',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Bar
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(context, '/location-picker');
                          _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loc.cityName ?? 'Select your location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: loc.hasLocation ? Colors.black87 : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ActionItem(
                            icon: Icons.add_task_rounded,
                            label: 'Book Now',
                            color: Colors.emerald,
                            onTap: () => Navigator.pushNamed(context, '/bookings/create'),
                          ),
                          _ActionItem(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Subscribe',
                            color: Colors.amber[700]!,
                            onTap: () => Navigator.pushNamed(context, '/plans'),
                          ),
                          _ActionItem(
                            icon: Icons.storefront_rounded,
                            label: 'Shop',
                            color: Colors.blueAccent,
                            onTap: () => Navigator.pushNamed(context, '/shop'),
                          ),
                          _ActionItem(
                            icon: Icons.menu_book_rounded,
                            label: 'Blogs',
                            color: Colors.purpleAccent,
                            onTap: () => Navigator.pushNamed(context, '/blogs'),
                          ),
                        ],
                      ).animate(interval: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      if (_bookings.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upcoming Visits',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/bookings'),
                              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._bookings.take(2).map((b) => _ModernBookingCard(booking: b)).toList(),
                        const SizedBox(height: 24),
                      ],

                      // AI Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF14B8A6).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Identify Your Plants',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'AI-powered identification & care tips',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/plant'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0F766E),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Try Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.psychology_outlined, color: Colors.white, size: 80)
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Featured Care Plans',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ..._plans.take(3).map((p) => _ModernPlanCard(plan: p)).toList(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ],
    );
  }
}

class _ModernBookingCard extends StatelessWidget {
  final Map booking;
  const _ModernBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['booking_number'] ?? '#ORD-000',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      booking['scheduled_date'] ?? 'TBD',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: (booking['status'] ?? 'Pending').toString().toUpperCase(),
                color: _getStatusColor(booking['status']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking['gardener']?['name'] ?? 'Assigning Gardener...',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                '₹${booking['total_amount']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _ModernPlanCard extends StatelessWidget {
  final Map plan;
  const _ModernPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  plan['description'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${plan['price']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
              ),
              Text(
                plan['plan_type'] == 'subscription' ? '/month' : '/visit',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
