import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';

/// Swiggy-style location picker:
///  1. GPS detect button
///  2. List of serviceable geofences with map preview
///  3. On select → saves to LocationProvider and returns
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    final lp = context.read<LocationProvider>();
    if (lp.geofences.isEmpty) {
      lp.loadGeofences().then((_) {
        if (mounted) setState(() => _filtered = lp.geofences);
      });
    } else {
      _filtered = lp.geofences;
    }
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    final all = context.read<LocationProvider>().geofences;
    setState(() => _filtered = q.isEmpty
        ? all
        : all
            .where((g) =>
                (g['name'] ?? '').toLowerCase().contains(q) ||
                (g['city'] ?? '').toLowerCase().contains(q))
            .toList());
  }

  Future<void> _detectGps() async {
    setState(() => _detecting = true);
    final lp = context.read<LocationProvider>();
    final ok = await lp.detectAndSetLocation();
    setState(() => _detecting = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect location. Please pick manually.')));
    }
  }

  void _pick(Map<String, dynamic> geofence) {
    context.read<LocationProvider>().selectGeofence(geofence);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search city or zone...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.primary),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── GPS detect ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _detecting ? null : _detectGps,
                icon: _detecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 20),
                label: Text(_detecting
                    ? 'Detecting…'
                    : 'Use My Current Location'),
              ),
            ),
          ),

          // ── Map preview of current selection ─────────────────────
          if (lp.lat != null && lp.lng != null)
            SizedBox(
              height: 160,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(lp.lat!, lp.lng!),
                  zoom: 12,
                  interactiveFlags: InteractiveFlag.none,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gharkamali.customer',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(lp.lat!, lp.lng!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin,
                          color: AppTheme.primary, size: 40),
                    ),
                  ]),
                ],
              ),
            ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lp.geofences.isEmpty
                    ? 'Loading service areas…'
                    : 'Available Service Areas (${_filtered.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),

          // ── Geofence list ─────────────────────────────────────────
          Expanded(
            child: lp.loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No service areas found',
                            style: TextStyle(
                                color: AppTheme.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final g = _filtered[i];
                          final selected =
                              lp.geofenceId == (g['id'] as int?);
                          return GkmCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => _pick(g),
                            child: Row(children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.location_city,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.primary,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(g['name'] ?? '',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selected
                                                ? AppTheme.primary
                                                : AppTheme.textPrimary)),
                                    Text(g['city'] ?? '',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text('From ₹${g['base_price']}',
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    if (selected)
                                      const Icon(Icons.check_circle,
                                          color: AppTheme.primary, size: 18),
                                  ]),
                            ]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
