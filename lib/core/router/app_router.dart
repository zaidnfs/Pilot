import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/kyc_screen.dart';
import '../../features/shared/screens/home_screen.dart';
import '../../features/shared/screens/profile_screen.dart';
import '../../features/requester/screens/store_list_screen.dart';
import '../../features/requester/screens/create_order_screen.dart';
import '../../features/requester/screens/order_tracking_screen.dart';
import '../../features/traveler/screens/available_orders_screen.dart';
import '../../features/traveler/screens/active_delivery_screen.dart';
import '../../features/traveler/screens/delivery_complete_screen.dart';
import '../../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/otp');

      // TEMP: Auth bypass for UI testing.
      // Uncomment the lines below to re-enable authentication.
      // if (!isAuthenticated && !isAuthRoute) return '/login';
      // if (isAuthenticated && isAuthRoute) return '/home';
      
      if (state.matchedLocation == '/') return '/home';
      return null;
    },
    routes: [
      // ─── Auth ────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/kyc',
        name: 'kyc',
        builder: (context, state) => const KycScreen(),
      ),

      // ─── Main App ────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ─── Requester ──────────────────────────────────────────
      GoRoute(
        path: '/stores',
        name: 'stores',
        builder: (context, state) => const StoreListScreen(),
      ),
      GoRoute(
        path: '/order/create/:storeId',
        name: 'createOrder',
        builder: (context, state) {
          final storeId = int.parse(state.pathParameters['storeId']!);
          return CreateOrderScreen(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/order/track/:orderId',
        name: 'trackOrder',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return OrderTrackingScreen(orderId: orderId);
        },
      ),

      // ─── Traveler ───────────────────────────────────────────
      GoRoute(
        path: '/traveler/orders',
        name: 'availableOrders',
        builder: (context, state) => const AvailableOrdersScreen(),
      ),
      GoRoute(
        path: '/traveler/delivery/:orderId',
        name: 'activeDelivery',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return ActiveDeliveryScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/traveler/complete/:orderId',
        name: 'deliveryComplete',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return DeliveryCompleteScreen(orderId: orderId);
        },
      ),
    ],
  );
});
