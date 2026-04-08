import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import 'services/api_service.dart';
import 'services/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/booking/bookings_screen.dart';
import 'screens/booking/create_booking_screen.dart';
import 'screens/booking/booking_detail_screen.dart';
import 'screens/booking/track_gardener_screen.dart';
import 'screens/booking/reschedule_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/blog/blog_list_screen.dart';
import 'screens/subscription/plans_screen.dart';
import 'screens/subscription/my_subscriptions_screen.dart';
import 'screens/subscription/schedule_subscription_screen.dart';
import 'screens/plant/plant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/wallet_screen.dart';
import 'screens/profile/notifications_screen.dart';
import 'screens/profile/complaints_screen.dart';
import 'screens/booking/raise_complaint_screen.dart';
import 'screens/booking/addon_picker_screen.dart';
import 'screens/home/service_areas_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(prefs);
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, prefs)),
      ],
      child: MaterialApp(
        title: 'Ghar Ka Mali',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
              TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
            },
          ),
        ),
        initialRoute: '/',
        routes: {
          '/':               (_) => const SplashScreen(),
          '/login':          (_) => const LoginScreen(),
          '/home':           (_) => const HomeScreen(),
          '/bookings':       (_) => const BookingsScreen(),
          '/bookings/create':(_) => const CreateBookingScreen(),
          '/plans':          (_) => const PlansScreen(),
          '/subscriptions':  (_) => const MySubscriptionsScreen(),
          '/plant':          (_) => const PlantScreen(),
          '/profile':        (_) => const ProfileScreen(),
          '/profile/edit':   (_) => const EditProfileScreen(),
          '/wallet':         (_) => const WalletScreen(),
          '/notifications':  (_) => const NotificationsScreen(),
          '/complaints':     (_) => const ComplaintsScreen(),
          '/service-areas':  (_) => const ServiceAreasScreen(),
          '/shop':           (_) => const ShopScreen(),
          '/blogs':          (_) => const BlogListScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/booking-detail':
              return MaterialPageRoute(
                builder: (_) => BookingDetailScreen(booking: settings.arguments as Map<String, dynamic>));
            case '/track':
              return MaterialPageRoute(
                builder: (_) => TrackGardenerScreen(bookingId: settings.arguments as int));
            case '/add-addons':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(builder: (_) => AddonPickerScreen(bookingId: args['booking_id'], bookingNumber: args['booking_number']));
            case '/raise-complaint':
              return MaterialPageRoute(
                builder: (_) => RaiseComplaintScreen(booking: settings.arguments as Map<String, dynamic>?));
            case '/reschedule':
              return MaterialPageRoute(
                builder: (_) => RescheduleScreen(booking: settings.arguments as Map<String, dynamic>));
            case '/payment':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  type: args['type'], bookingId: args['booking_id'],
                  subscriptionId: args['subscription_id'],
                  amount: (args['amount'] as num?)?.toDouble(),
                  label: args['label'],
                ));
            case '/schedule-subscription':
              return MaterialPageRoute(
                builder: (_) => ScheduleSubscriptionScreen(subscription: settings.arguments as Map<String, dynamic>));
          }
          return null;
        },
      ),
    );
  }
}
