import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({super.key});
  @override
  State<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  List _zones = [];
  List _filteredZones = [];
  bool _loading = true;
  bool _checking = false;
  bool? _isServiceable;
  Map? _nearestZone;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().getZones();
      setState(() { _zones = res['data'] ?? []; _filteredZones = _zones; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() => _filteredZones = _zones.where((z) =>
      (z['name'] ?? '').toLowerCase().contains(q) ||
      (z['city'] ?? '').toLowerCase().contains(q) ||
      (z['state'] ?? '').toLowerCase().contains(q)
    ).toList());
  }

  Future<void> _checkMyLocation() async {
    setState(() => _checking = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) { _snack('Location permission denied'); return; }

      final pos = await Geolocator.getCurrentPosition();
      final res = await context.read<ApiService>().checkServiceability(pos.latitude, pos.longitude);
      final data = res['data'];
      setState(() {
        _isServiceable = data['serviceable'] == true;
        _nearestZone = (data['zones'] as List?)?.isNotEmpty == true ? data['zones'][0] : null;
      });
    } catch (e) { _snack(e.toString()); }
    setState(() => _checking = false);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Service Areas')),
    body: Column(children: [
      // Location check banner
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search city or zone...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 42,
            child: OutlinedButton.icon(
              onPressed: _checking ? null : _checkMyLocation,
              icon: _checking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Check if my area is serviceable'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: Size.zero,
              ),
            ),
          ),
          if (_isServiceable != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isServiceable! ? AppTheme.success.withOpacity(0.08) : AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isServiceable! ? AppTheme.success : AppTheme.error, width: 1),
              ),
              child: Row(children: [
                Icon(_isServiceable! ? Icons.check_circle : Icons.cancel,
                  color: _isServiceable! ? AppTheme.success : AppTheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _isServiceable!
                      ? 'Great! We service your area${_nearestZone != null ? ': ${_nearestZone!['name']}, ${_nearestZone!['city']}' : ''}. Book now!'
                      : 'Sorry, we don\'t serve your area yet. Coming soon!',
                  style: TextStyle(
                    color: _isServiceable! ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.w500, fontSize: 13,
                  ),
                )),
              ]),
            ),
          ],
        ]),
      ),

      // Zones list
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _filteredZones.isEmpty
              ? const Center(child: Text('No zones found', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredZones.length,
                  itemBuilder: (_, i) {
                    final z = _filteredZones[i];
                    return GkmCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => Navigator.pop(context, z),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(z['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${z['city']}, ${z['state']}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('From ₹${z['base_price']} · ₹${z['price_per_plant']}/plant extra',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: z['is_active'] == true ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            z['is_active'] == true ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: z['is_active'] == true ? AppTheme.success : AppTheme.error,
                              fontSize: 11, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
      ),
    ]),
  );
}
