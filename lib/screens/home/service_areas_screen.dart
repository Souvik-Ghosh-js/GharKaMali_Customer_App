import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';

class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({super.key});
  @override
  State<ServiceAreasScreen> createState() =>
      _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  List _geofences = [];
  List _filteredGeofences = [];
  bool _loading = true;
  bool _checking = false;
  bool? _isServiceable;
  Map? _nearestGeofence;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // FIX: use getGeofences() not getZones()
      final res = await context.read<ApiService>().getGeofences();
      setState(() {
        _geofences = res['data'] ?? [];
        _filteredGeofences = _geofences;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filteredGeofences = _geofences
        .where((g) =>
            (g['name'] ?? '').toLowerCase().contains(q) ||
            (g['city'] ?? '').toLowerCase().contains(q))
        .toList());
  }

  Future<void> _checkMyLocation() async {
    setState(() => _checking = true);
    try {
      final loc = context.read<LocationProvider>();
      final ok = await loc.detectAndSetLocation();
      if (ok) {
        final res = await context
            .read<ApiService>()
            .checkServiceability(loc.lat!, loc.lng!);
        final data = res['data'];
        final zones = data['zones'] as List?;
        setState(() {
          _isServiceable = data['serviceable'] == true;
          _nearestGeofence =
              zones?.isNotEmpty == true ? zones![0] : null;
        });
      } else {
        _snack('Could not get location');
      }
    } catch (e) {
      _snack(e.toString());
    }
    setState(() => _checking = false);
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Service Areas')),
        body: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search city or zone...',
                  prefixIcon:
                      Icon(Icons.search, color: AppTheme.primary),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkMyLocation,
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary))
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text(
                      'Check if my area is serviceable'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(
                          color: AppTheme.primary),
                      minimumSize: Size.zero),
                ),
              ),
              if (_isServiceable != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isServiceable!
                        ? AppTheme.success.withOpacity(0.08)
                        : AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _isServiceable!
                            ? AppTheme.success
                            : AppTheme.error,
                        width: 1),
                  ),
                  child: Row(children: [
                    Icon(
                        _isServiceable!
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _isServiceable!
                            ? AppTheme.success
                            : AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      _isServiceable!
                          ? 'Great! We service your area${_nearestGeofence != null ? ': ${_nearestGeofence!['name']}, ${_nearestGeofence!['city']}' : ''}. Book now!'
                          : 'Sorry, we don\'t serve your area yet. Coming soon!',
                      style: TextStyle(
                          color: _isServiceable!
                              ? AppTheme.success
                              : AppTheme.error,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    )),
                  ]),
                ),
              ],
            ]),
          ),

          // Mini map showing all geofence cities as markers
          if (!_loading && _geofences.isNotEmpty)
            SizedBox(
              height: 120,
              child: FlutterMap(
                options: const MapOptions(
                  center: LatLng(20.5937, 78.9629),
                  zoom: 4,
                  interactiveFlags: InteractiveFlag.none,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gharkamali.customer',
                  ),
                ],
              ),
            ),

          Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : _filteredGeofences.isEmpty
                      ? const Center(
                          child: Text('No service areas found',
                              style: TextStyle(
                                  color:
                                      AppTheme.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredGeofences.length,
                          itemBuilder: (_, i) {
                            final g = _filteredGeofences[i];
                            return GkmCard(
                              padding: const EdgeInsets.all(16),
                              onTap: () =>
                                  Navigator.pop(context, g),
                              child: Row(children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.location_on,
                                      color: AppTheme.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                  Text(g['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 15)),
                                  Text(g['city'] ?? '',
                                      style: const TextStyle(
                                          color: AppTheme
                                              .textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'From ₹${g['base_price']} · ₹${g['price_per_plant']}/plant extra',
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w500)),
                                ])),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: g['is_active'] == true
                                        ? AppTheme.success
                                            .withOpacity(0.1)
                                        : AppTheme.error
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    g['is_active'] == true
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                        color:
                                            g['is_active'] == true
                                                ? AppTheme.success
                                                : AppTheme.error,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                ),
                              ]),
                            );
                          },
                        )),
        ]),
      );
}
