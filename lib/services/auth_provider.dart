import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final SharedPreferences _prefs;
  Map<String, dynamic>? _user;
  bool _loading = false;

  AuthProvider(this._api, this._prefs) {
    _loadUser();
  }

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn =>
      _user != null && _prefs.getString('token') != null;
  String? get token => _prefs.getString('token');

  void _loadUser() {
    final u = _prefs.getString('user');
    if (u != null) _user = jsonDecode(u);
  }

  Future<void> sendOtp(String phone) => _api.sendOtp(phone);

  Future<void> verifyOtp(String phone, String otp,
      {String? name}) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.verifyOtp(phone, otp, name: name);
      final data = res['data'];
      await _prefs.setString('token', data['token']);
      await _prefs.setString('user', jsonEncode(data['user']));
      _user = data['user'];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _prefs.remove('token');
    await _prefs.remove('user');
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.getProfile();
      _user = res['data'];
      await _prefs.setString('user', jsonEncode(_user));
      notifyListeners();
    } catch (_) {}
  }
}
