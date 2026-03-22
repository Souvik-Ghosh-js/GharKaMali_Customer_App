import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = ['All', 'Active', 'Completed', 'Cancelled'];
  final _statusMap = {'All': null, 'Active': 'assigned,in_progress,pending,en_route,arrived', 'Completed': 'completed', 'Cancelled': 'cancelled'};
  Map<String, List> _data = {};
  Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) _loadTab(_tabs[_tab.index]); });
    _loadTab('All');
  }

  Future<void> _loadTab(String tab) async {
    if (_loading[tab] == true) return;
    setState(() => _loading[tab] = true);
    try {
      final api = context.read<ApiService>();
      final status = _statusMap[tab];
      final res = await api.getMyBookings(status: status, page: 1);
      setState(() => _data[tab] = res['data']['bookings'] ?? []);
    } catch (_) {}
    setState(() => _loading[tab] = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Bookings'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.pushNamed(context, '/bookings/create').then((_) => _loadTab('All')),
        )
      ],
      bottom: TabBar(
        controller: _tab,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        if (_loading[tab] == true && (_data[tab]?.isEmpty ?? true)) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final items = _data[tab] ?? [];
        if (items.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🌱', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No bookings here', style: TextStyle(color: AppTheme.textSecondary)),
        ]));
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => _loadTab(tab),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _BookingTile(booking: items[i], onRefresh: () => _loadTab(tab)),
          ),
        );
      }).toList(),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/bookings/create').then((_) => _loadTab('All')),
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Book Now', style: TextStyle(color: Colors.white)),
    ),
  );
}

class _BookingTile extends StatelessWidget {
  final Map booking;
  final VoidCallback onRefresh;
  const _BookingTile({required this.booking, required this.onRefresh});

  static const _statusColors = {
    'completed': (Color(0xFFDCFCE7), Color(0xFF15803D)),
    'pending': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'assigned': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'in_progress': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'en_route': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'cancelled': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'failed': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'pending';
    final colors = _statusColors[status] ?? (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    return GkmCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.pushNamed(context, '/booking-detail', arguments: Map<String, dynamic>.from(booking)).then((_) => onRefresh()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(booking['booking_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' '), style: TextStyle(color: colors.$2, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(booking['scheduled_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text('₹${booking['total_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(booking['gardener']?['name'] ?? 'Gardener pending', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          if (booking['rating'] != null) Row(children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            Text(' ${booking['rating']}', style: const TextStyle(fontSize: 13)),
          ]),
        ]),
        if (['in_progress', 'assigned', 'en_route', 'arrived'].contains(status)) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/track', arguments: booking['id'] as int),
              icon: const Icon(Icons.location_on, size: 15),
              label: const Text('Track', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary), minimumSize: const Size(0, 36)),
            )),
          ]),
        ],
      ]),
    );
  }
}
