import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _geofences = [];
  Map<String, dynamic>? _selectedGeofence;
  double? _lat;
  double? _lng;
  String? _cityName;
  bool _loading = false;

  List<Map<String, dynamic>> get geofences => _geofences;
  Map<String, dynamic>? get selectedGeofence => _selectedGeofence;
  int? get geofenceId => _selectedGeofence?['id'] as int?;
  String? get cityName =>
      _cityName ?? (_selectedGeofence?['city'] as String?);
  double? get lat => _lat;
  double? get lng => _lng;
  bool get loading => _loading;
  bool get hasLocation => _selectedGeofence != null;

  final ApiService _api;
  LocationProvider(this._api) {
    _restore();
  }

  /// Load geofences from backend
  Future<void> loadGeofences() async {
    try {
      final res = await _api.getGeofences();
      _geofences =
          List<Map<String, dynamic>>.from(res['data'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  /// Detect current GPS position and match to nearest geofence
  Future<bool> detectAndSetLocation() async {
    _loading = true;
    notifyListeners();
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) {
        _loading = false;
        notifyListeners();
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _loading = false;
        notifyListeners();
        return false;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Try serviceability check first
      try {
        final res =
            await _api.checkServiceability(pos.latitude, pos.longitude);
        final zones =
            res['data']?['zones'] as List?;
        if (zones != null && zones.isNotEmpty) {
          _selectedGeofence = Map<String, dynamic>.from(zones[0]);
          _cityName = _selectedGeofence!['city'] as String?;
          await _persist();
          _loading = false;
          notifyListeners();
          return true;
        }
      } catch (_) {}

      // Fallback: pick first geofence from list
      if (_geofences.isEmpty) await loadGeofences();
      if (_geofences.isNotEmpty) {
        _selectedGeofence = _geofences[0];
        _cityName = _selectedGeofence!['city'] as String?;
        await _persist();
      }
      _loading = false;
      notifyListeners();
      return _selectedGeofence != null;
    } catch (_) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Manually select a geofence (from LocationPickerScreen)
  void selectGeofence(Map<String, dynamic> geofence) {
    _selectedGeofence = geofence;
    _cityName = geofence['city'] as String?;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedGeofence != null) {
        await prefs.setInt(
            'geofence_id', _selectedGeofence!['id'] as int);
        await prefs.setString(
            'geofence_city', _selectedGeofence!['city'] as String? ?? '');
      }
      if (_lat != null) await prefs.setDouble('loc_lat', _lat!);
      if (_lng != null) await prefs.setDouble('loc_lng', _lng!);
    } catch (_) {}
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('geofence_id');
      final city = prefs.getString('geofence_city');
      _lat = prefs.getDouble('loc_lat');
      _lng = prefs.getDouble('loc_lng');
      if (id != null) {
        _selectedGeofence = {'id': id, 'city': city ?? ''};
        _cityName = city;
        notifyListeners();
      }
    } catch (_) {}
  }
}
