import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://gkm.gobt.in/api/';
  final SharedPreferences prefs;
  ApiService(this.prefs);

  String? get token => prefs.getString('token');
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> _multipart(String method, String path, Map<String, String> fields, {File? file, String fieldName = 'file'}) async {
    final req = http.MultipartRequest(method, Uri.parse('$baseUrl$path'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    if (file != null) req.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(body['message'] ?? 'Request failed', res.statusCode);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String phone) =>
      post('/auth/send-otp', {'phone': phone});
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? name}) =>
      post('/auth/verify-otp', {'phone': phone, 'otp': otp, if (name != null) 'name': name});
  Future<Map<String, dynamic>> getProfile() => get('/auth/profile');
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      put('/auth/profile', data);
  Future<Map<String, dynamic>> updateProfileWithImage(Map<String, dynamic> data, File image) =>
      _multipart('PUT', '/auth/profile',
        data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        file: image, fieldName: 'profile_image');

  // ── Plans & Zones ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPlans() => get('/plans');
  Future<Map<String, dynamic>> getZones() => get('/zones');
  Future<Map<String, dynamic>> checkServiceability(double lat, double lng) =>
      get('/payments/check-serviceability?latitude=$lat&longitude=$lng');

  // ── Bookings ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) =>
      post('/bookings', data);
  Future<Map<String, dynamic>> getMyBookings({String? status, int page = 1}) =>
      get('/bookings/my?page=$page${status != null ? '&status=$status' : ''}');
  Future<Map<String, dynamic>> getBookingDetail(int id) => get('/bookings/$id');
  Future<Map<String, dynamic>> rateBooking(int bookingId, int rating, {String? review}) =>
      post('/bookings/rate', {'booking_id': bookingId, 'rating': rating, if (review != null) 'review': review});
  Future<Map<String, dynamic>> cancelBooking(int bookingId, {String? reason}) =>
      post('/bookings/cancel', {'booking_id': bookingId, if (reason != null) 'reason': reason});
  Future<Map<String, dynamic>> getGardenerLocation(int bookingId) =>
      get('/bookings/track/$bookingId');
  Future<Map<String, dynamic>> rescheduleBooking(int bookingId, String newDate, {String? newTime}) =>
      post('/payments/reschedule', {'booking_id': bookingId, 'new_date': newDate, if (newTime != null) 'new_time': newTime});

  // ── Subscriptions ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> subscribe(Map<String, dynamic> data) =>
      post('/subscriptions', data);
  Future<Map<String, dynamic>> getMySubscriptions() => get('/subscriptions/my');
  Future<Map<String, dynamic>> cancelSubscription(int id) =>
      put('/subscriptions/$id/cancel', {});
  Future<Map<String, dynamic>> pauseSubscription(int id) =>
      patch('/subscriptions/$id/pause', {});
  Future<Map<String, dynamic>> resumeSubscription(int id) =>
      patch('/subscriptions/$id/resume', {});
  Future<Map<String, dynamic>> selectSubscriptionDates(int id, List<String> dates) =>
      post('/subscriptions/$id/select-dates', {'dates': dates});

  // ── Payments (PayU) ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> initiatePayment({
    required String type, int? bookingId, int? subscriptionId, int? orderId, double? amount,
  }) => post('/payments/initiate', {
    'type': type,
    if (bookingId != null) 'booking_id': bookingId,
    if (subscriptionId != null) 'subscription_id': subscriptionId,
    if (orderId != null) 'order_id': orderId,
    if (amount != null) 'amount': amount,
  });
  Future<Map<String, dynamic>> checkPaymentStatus(String txnid) =>
      get('/payments/status/$txnid');
  Future<Map<String, dynamic>> getMyPayments({int page = 1}) =>
      get('/payments/my?page=$page');
  Future<Map<String, dynamic>> walletTopup(double amount) =>
      post('/payments/wallet-topup', {'amount': amount});

  // ── Plantopedia ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> identifyPlant(File image) =>
      _multipart('POST', '/plants/identify', {}, file: image, fieldName: 'image');
  Future<Map<String, dynamic>> getPlantHistory() => get('/plants/history');

  // ── Shop ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getShopCategories() => get('/shop/categories');
  Future<Map<String, dynamic>> getShopProducts({int? categoryId, String? search}) =>
      get('/shop/products?${categoryId != null ? 'category_id=$categoryId' : ''}${search != null ? '&search=$search' : ''}');
  Future<Map<String, dynamic>> getProductDetail(int id) => get('/shop/products/$id');
  Future<Map<String, dynamic>> createShopOrder(Map<String, dynamic> data) =>
      post('/shop/orders', data);
  Future<Map<String, dynamic>> getMyOrders() => get('/shop/orders/my');

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications() => get('/notifications');
  Future<Map<String, dynamic>> markNotificationRead(int id) =>
      put('/notifications/$id/read', {});

  // ── Blogs ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBlogs({int page = 1}) => get('/blogs?page=$page');
  Future<Map<String, dynamic>> getBlogBySlug(String slug) => get('/blogs/$slug');
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
