import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class TrackGardenerScreen extends StatefulWidget {
  final int bookingId;
  const TrackGardenerScreen({super.key, required this.bookingId});
  @override
  State<TrackGardenerScreen> createState() =>
      _TrackGardenerScreenState();
}

class _TrackGardenerScreenState
    extends State<TrackGardenerScreen> {
  Map? _location;
  Map? _booking;
  Timer? _timer;
  bool _loading = true;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
        const Duration(seconds: 10), (_) => _loadLocation());
  }

  Future<void> _load() async {
    await _loadBooking();
    await _loadLocation();
  }

  Future<void> _loadBooking() async {
    try {
      final res = await context
          .read<ApiService>()
          .getBookingDetail(widget.bookingId);
      setState(() => _booking = res['data']);
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    try {
      final res = await context
          .read<ApiService>()
          .getGardenerLocation(widget.bookingId);
      setState(() {
        _location = res['data'];
        _loading = false;
      });
      // Pan map to gardener location
      if (_location != null) {
        final lat =
            double.tryParse(_location!['latitude'].toString());
        final lng =
            double.tryParse(_location!['longitude'].toString());
        if (lat != null && lng != null) {
          _mapCtrl.move(LatLng(lat, lng), 15);
        }
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _callGardener(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gardener = _booking?['gardener'];
    final status = _booking?['status'] ?? '';

    // Default centre (India)
    final double defLat = _location != null
        ? double.tryParse(_location!['latitude'].toString()) ?? 20.5937
        : 20.5937;
    final double defLng = _location != null
        ? double.tryParse(_location!['longitude'].toString()) ?? 78.9629
        : 78.9629;

    return Scaffold(
      appBar: AppBar(title: const Text('Track Gardener')),
      body: Column(children: [
        // ── Live OpenStreetMap ────────────────────────────────────
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                center: LatLng(defLat, defLng),
                zoom: _location != null ? 15 : 5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gharkamali.customer',
                ),
                if (_location != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(defLat, defLng),
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2)),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ]),
              ],
            ),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary)),
            if (_location == null && !_loading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                      'Waiting for gardener location…',
                      style: TextStyle(
                          fontWeight: FontWeight.w500)),
                ),
              ),
          ]),
        ),

        // ── Bottom panel ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Gardener Info',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            if (gardener != null)
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      AppTheme.primary.withOpacity(0.1),
                  child: Text(
                      (gardener['name'] as String? ?? 'G')[0],
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                  Text(gardener['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(gardener['phone'] ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary)),
                ])),
                // FIX: wired Call button using url_launcher
                GestureDetector(
                  onTap: () {
                    final phone =
                        gardener['phone'] as String? ?? '';
                    if (phone.isNotEmpty) _callGardener(phone);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.phone,
                          color: AppTheme.primary, size: 18),
                      SizedBox(width: 6),
                      Text('Call',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ])
            else
              const Text('Gardener not assigned yet',
                  style: TextStyle(
                      color: AppTheme.textSecondary)),
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
  static const _steps = [
    'assigned',
    'en_route',
    'arrived',
    'in_progress',
    'completed'
  ];
  static const _labels = [
    'Assigned',
    'En Route',
    'Arrived',
    'In Progress',
    'Completed'
  ];
  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status);
    return Row(
        children: List.generate(_steps.length, (i) {
      final done = i <= current;
      return Expanded(
          child: Column(children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppTheme.primary : AppTheme.border),
          child: done
              ? const Icon(Icons.check,
                  color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 4),
        Text(_labels[i],
            style: TextStyle(
                fontSize: 9,
                color: done
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
                fontWeight: done
                    ? FontWeight.w600
                    : FontWeight.normal),
            textAlign: TextAlign.center),
      ]));
    }));
  }
}
