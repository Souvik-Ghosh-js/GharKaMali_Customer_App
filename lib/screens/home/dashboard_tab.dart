import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50, top: -50,
                        child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                      Positioned(
                        left: -30, bottom: -30,
                        child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.03)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Hello, ${user?['name']?.split(' ')[0] ?? 'there'} 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                            ).animate().fadeIn().slideX(),
                            const SizedBox(height: 6),
                            Text(
                              'Let\'s make your garden thrive today',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Quick Actions
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _QuickAction(icon: Icons.add_circle_outline, label: 'Book Now', color: AppTheme.primary,
                            onTap: () => Navigator.pushNamed(context, '/bookings/create')),
                          _QuickAction(icon: Icons.subscriptions_outlined, label: 'Subscribe', color: Colors.orange,
                            onTap: () => Navigator.pushNamed(context, '/plans')),
                          _QuickAction(icon: Icons.shopping_bag_outlined, label: 'Store', color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, '/shop')),
                          _QuickAction(icon: Icons.article_outlined, label: 'Blogs', color: Colors.deepPurple,
                            onTap: () => Navigator.pushNamed(context, '/blogs')),
                          _QuickAction(icon: Icons.local_florist_outlined, label: 'Identify', color: Colors.teal,
                            onTap: () => Navigator.pushNamed(context, '/plant')),
                        ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Active bookings
                    if (_bookings.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Upcoming Visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/bookings'),
                            child: const Text('View All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._bookings.take(2).map((b) => _BookingCard(booking: b))
                          .toList().animate(interval: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                    ],

                    // Plantopedia banner
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, '/plant'),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('NEW FEATURE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('AI Plantopedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                                      const SizedBox(height: 4),
                                      Text('Identify any plant instantly with your camera', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, color: Colors.teal, size: 28),
                                ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds, duration: 1.5.seconds),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 32),

                    // Plans section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Our Care Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        IconButton(onPressed: () => Navigator.pushNamed(context, '/plans'), icon: const Icon(Icons.arrow_forward, size: 20)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    else
                      ..._plans.map((p) => _PlanCard(plan: p))
                          .toList().animate(interval: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(width: 80, child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    ),
  ));
}

class _BookingCard extends StatelessWidget {
  final Map booking;
  const _BookingCard({required this.booking});
  @override
  Widget build(BuildContext context) => GkmCard(
    padding: const EdgeInsets.all(16),
    onTap: () => Navigator.pushNamed(context, '/booking-detail', arguments: Map<String, dynamic>.from(booking)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.grass, color: AppTheme.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary)),
          Text(booking['scheduled_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        GkmBadge(booking['status'] ?? ''),
      ]),
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(booking['gardener']?['name'] ?? 'Assigning gardener...', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text('₹${booking['total_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ]),
      if (booking['status'] == 'in_progress' || booking['status'] == 'assigned') ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 36,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/track', arguments: booking['id'] as int),
            icon: const Icon(Icons.location_on, size: 16), label: const Text('Track Gardener'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary), minimumSize: Size.zero),
          ),
        ),
      ],
    ]),
  );
}

class _PlanCard extends StatelessWidget {
  final Map plan;
  const _PlanCard({required this.plan});
  @override
  Widget build(BuildContext context) {
    final isSubscription = plan['plan_type'] == 'subscription';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GkmCard(
        padding: const EdgeInsets.all(20),
        onTap: () => Navigator.pushNamed(context, '/plans'),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(plan['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              if (isSubscription) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Popular', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(plan['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            if (isSubscription) Text('${plan['visits_per_month']} visits/month · Max ${plan['max_plants']} plants',
              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
          ])),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${plan['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary)),
            Text(isSubscription ? '/month' : '/visit', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    );
  }
}
