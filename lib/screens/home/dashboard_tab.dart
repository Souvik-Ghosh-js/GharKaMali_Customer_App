import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      final [b, p] = await Future.wait([
        api.getMyBookings(status: 'assigned,in_progress,pending', page: 1),
        api.getPlans(),
      ]);
      setState(() {
        _bookings = b['data']['bookings'] ?? [];
        _plans = p['data'] ?? [];
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
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false, pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${user?['name']?.split(' ')[0] ?? 'there'} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('How\'s your garden today?',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    Row(children: [
                      _QuickAction(icon: Icons.add_circle_outline, label: 'Book Now', color: AppTheme.primary,
                        onTap: () => Navigator.pushNamed(context, '/bookings/create')),
                      const SizedBox(width: 12),
                      _QuickAction(icon: Icons.subscriptions_outlined, label: 'Subscribe', color: Colors.orange,
                        onTap: () => Navigator.pushNamed(context, '/plans')),
                      const SizedBox(width: 12),
                      _QuickAction(icon: Icons.local_florist_outlined, label: 'Identify Plant', color: Colors.teal,
                        onTap: () => Navigator.pushNamed(context, '/plant')),
                      const SizedBox(width: 12),
                      _QuickAction(icon: Icons.history, label: 'History', color: Colors.purple,
                        onTap: () => Navigator.pushNamed(context, '/bookings')),
                    ]),

                    const SizedBox(height: 28),

                    // Active bookings
                    if (_bookings.isNotEmpty) ...[
                      Row(children: [
                        const Text('Active Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(onPressed: () => Navigator.pushNamed(context, '/bookings'),
                          child: const Text('See all', style: TextStyle(color: AppTheme.primary))),
                      ]),
                      const SizedBox(height: 12),
                      ..._bookings.take(2).map((b) => _BookingCard(booking: b)),
                      const SizedBox(height: 20),
                    ],

                    // Plans
                    const Text('Our Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Choose what suits your garden', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),

                    if (_loading)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    else
                      ..._plans.map((p) => _PlanCard(plan: p)),

                    const SizedBox(height: 24),

                    // Plantopedia banner
                    GkmCard(
                      padding: const EdgeInsets.all(20),
                      onTap: () => Navigator.pushNamed(context, '/plant'),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('🌿 AI Plantopedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Identify any plant instantly with AI', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                            child: const Text('Try Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ])),
                        const Text('📷', style: TextStyle(fontSize: 60)),
                      ]),
                    ),
                    const SizedBox(height: 80),
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
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
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
