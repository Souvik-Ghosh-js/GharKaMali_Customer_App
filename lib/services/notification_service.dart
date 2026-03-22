/**
 * notification_service.dart
 * Firebase Cloud Messaging setup for Customer App.
 *
 * Setup:
 *  1. Create a Firebase project at console.firebase.google.com
 *  2. Add Android app (package: com.gharkamali.customer)
 *  3. Download google-services.json → place in android/app/
 *  4. Add iOS app → download GoogleService-Info.plist → place in ios/Runner/
 *  5. In android/build.gradle: add classpath 'com.google.gms:google-services:4.4.0'
 *  6. In android/app/build.gradle: add apply plugin: 'com.google.gms.google-services'
 */

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Init Firebase
    await Firebase.initializeApp();

    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // Init local notifications (for foreground display)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Android notification channel
    const channel = AndroidNotificationChannel(
      'gkm_high_importance', 'Ghar Ka Mali',
      description: 'Gardening service updates',
      importance: Importance.high,
    );
    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get & save FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }

    // Token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'gkm_high_importance', 'Ghar Ka Mali',
              channelDescription: 'Gardening service updates',
              importance: Importance.high, priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['type'],
        );
      }
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App opened from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleMessage(initial);
  }

  static void _onTap(NotificationResponse response) {
    // Navigate based on payload type
    // This would use a global navigator key in production
  }

  static void _handleMessage(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    // In production: use global navigator key to push to relevant screen
    switch (type) {
      case 'booking_assigned':
      case 'en_route':
      case 'arrived':
      case 'completed':
        // Navigate to bookings screen
        break;
      case 'complaint_resolved':
        // Navigate to complaints screen
        break;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
