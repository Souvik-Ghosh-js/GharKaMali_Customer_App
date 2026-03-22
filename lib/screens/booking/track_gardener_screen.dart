import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class TrackGardenerScreen extends StatefulWidget {
  final int bookingId;
  const TrackGardenerScreen({super.key, required this.bookingId});
  @override
  State<TrackGardenerScreen> createState() => _TrackGardenerScreenState();
}

class _TrackGardenerScreenState extends State<TrackGardenerScreen> {
  Map? _location;
  Map? _booking;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadLocation());
  }

  Future<void> _load() async {
    await _loadBooking();
    await _loadLocation();
  }

  Future<void> _loadBooking() async {
    try {
      final res = await context.read<ApiService>().getBookingDetail(widget.bookingId);
      setState(() => _booking = res['data']);
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    try {
      final res = await context.read<ApiService>().getGardenerLocation(widget.bookingId);
      setState(() { _location = res['data']; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gardener = _booking?['gardener'];
    final status = _booking?['status'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Track Gardener')),
      body: Column(children: [
        // Map placeholder (replace with GoogleMap widget once keys configured)
        Expanded(
          child: Stack(children: [
            Container(
              color: const Color(0xFFE8F5E9),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(40)),
                  child: const Icon(Icons.person, color: Colors.white, size: 40)),
                const SizedBox(height: 12),
                const Text('🗺️ Live Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _location != null
                    ? 'Lat: ${_location!['latitude']}, Lng: ${_location!['longitude']}'
                    : 'Waiting for gardener location...',
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Add GOOGLE_MAPS_API_KEY in AndroidManifest.xml\nfor live map', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
              ])),
            ),
            if (_loading) const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ]),
        ),
        // Bottom panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gardener Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            if (gardener != null) Row(children: [
              CircleAvatar(
                radius: 28, backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text((gardener['name'] as String? ?? 'G')[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(gardener['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(gardener['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.phone, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Call', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]) else const Text('Gardener not assigned yet', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            _StatusTimeline(status: status),
          ]),
        ),
      ]),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});
  static const _steps = ['assigned', 'en_route', 'arrived', 'in_progress', 'completed'];
  static const _labels = ['Assigned', 'En Route', 'Arrived', 'In Progress', 'Completed'];
  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status);
    return Row(children: List.generate(_steps.length, (i) {
      final done = i <= current;
      return Expanded(child: Column(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppTheme.primary : AppTheme.border),
          child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
        ),
        const SizedBox(height: 4),
        Text(_labels[i], style: TextStyle(fontSize: 9, color: done ? AppTheme.primary : AppTheme.textSecondary, fontWeight: done ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
      ]));
    }));
  }
}
