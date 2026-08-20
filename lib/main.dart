import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// Services
import 'services/mock_data_service.dart';
import 'services/auth_service.dart';

// Screens
// Screens
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/bookings_management_screen.dart';
import 'screens/admin/booking_detail_screen.dart';
import 'screens/admin/map_editor_screen.dart';
import 'screens/admin/pricing_management_screen.dart';
import 'screens/admin/extras_management_screen.dart';
import 'screens/admin/qr_scanner_screen.dart';
import 'screens/admin/financial_dashboard_screen.dart';
import 'screens/admin/orders_management_screen.dart';
import 'screens/admin/daily_map_screen.dart';
import 'screens/admin/svg_library_screen.dart';
import 'screens/admin/menu_management_screen.dart';
import 'screens/admin/extra_orders_screen.dart';
import 'screens/user/extra_services_screen.dart';
import 'screens/admin/restaurant/restaurant_dashboard_screen.dart';
import 'screens/admin/restaurant/restaurant_map_editor_screen.dart';
import 'screens/admin/restaurant/restaurant_bookings_screen.dart';
import 'screens/admin/restaurant/table_booking_detail_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/booking_screen.dart';
import 'screens/user/restaurant_booking_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/menu_order_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  runApp(const BeachManagerApp());
}

class BeachManagerApp extends StatelessWidget {
  const BeachManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, MockDataService>(
          create: (context) => MockDataService(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, auth, previous) =>
              previous ?? MockDataService(auth),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          return MaterialApp.router(
            title: 'Beach Manager',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(),
            ),
            routerConfig: _createRouter(authService),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: authService.isAuthenticated ? '/' : '/login',
      redirect: (context, state) {
        final isAuthenticated = authService.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';
        final location = state.matchedLocation;

        // Redirect to login if not authenticated and not already on login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // Redirect to home if authenticated and on login page
        if (isAuthenticated && isLoginRoute) {
          return '/';
        }

        // A restaurant manager only ever sees their own admin section —
        // reachable straight from login, with no customer home screen or
        // beach admin in between (see auth_service.dart's demo accounts).
        final role = authService.currentUser?.role;
        if (role == UserRole.restaurantManager) {
          final isRestaurantAdmin = location.startsWith('/admin/restaurant');
          if (!isRestaurantAdmin) {
            return '/admin/restaurant/dashboard';
          }
        }

        // A beach manager sees the beach admin (and the customer app, for
        // the existing demo "browse as a customer too" flow) but not the
        // restaurant's own management screens — on the beach side they only
        // get the cross-reference badge on a booking that also has a table.
        if (role == UserRole.beachManager && location.startsWith('/admin/restaurant')) {
          return '/admin/dashboard';
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // User Routes
        GoRoute(
          path: '/',
          builder: (context, state) => const UserHomeScreen(),
        ),
        GoRoute(
          path: '/book',
          builder: (context, state) => const BookingScreen(),
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) => const MenuOrderScreen(),
        ),
        GoRoute(
          path: '/restaurant-book',
          builder: (context, state) => const RestaurantBookingScreen(),
        ),
        GoRoute(
          path: '/extra-services',
          builder: (context, state) => const ExtraServicesScreen(),
        ),

        // Admin Routes
        GoRoute(
          path: '/admin',
          redirect: (context, state) => authService.currentUser?.role == UserRole.restaurantManager
              ? '/admin/restaurant/dashboard'
              : '/admin/dashboard',
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/daily-map',
          builder: (context, state) => const DailyMapScreen(),
        ),
        GoRoute(
          path: '/admin/scan',
          builder: (context, state) => const QrScannerScreen(),
        ),
        GoRoute(
          path: '/admin/map',
          builder: (context, state) => const MapEditorScreen(),
        ),
        GoRoute(
          path: '/admin/svg-library',
          builder: (context, state) => const SvgLibraryScreen(),
        ),
        GoRoute(
          path: '/admin/pricing',
          builder: (context, state) => const PricingManagementScreen(),
        ),
        GoRoute(
          path: '/admin/extras',
          builder: (context, state) => const ExtrasManagementScreen(),
        ),
        GoRoute(
          path: '/admin/bookings',
          builder: (context, state) => const BookingsManagementScreen(),
        ),
        GoRoute(
          path: '/admin/bookings/:id',
          builder: (context, state) =>
              BookingDetailScreen(bookingId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const OrdersManagementScreen(),
        ),
        GoRoute(
          path: '/admin/menu',
          builder: (context, state) => const MenuManagementScreen(),
        ),
        GoRoute(
          path: '/admin/financial',
          builder: (context, state) => const FinancialDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/extra-orders',
          builder: (context, state) => const ExtraOrdersScreen(),
        ),

        // Restaurant admin routes
        GoRoute(
          path: '/admin/restaurant/dashboard',
          builder: (context, state) => const RestaurantDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/restaurant/map',
          builder: (context, state) => const RestaurantMapEditorScreen(),
        ),
        GoRoute(
          path: '/admin/restaurant/bookings',
          builder: (context, state) => const RestaurantBookingsScreen(),
        ),
        GoRoute(
          path: '/admin/restaurant/bookings/:id',
          builder: (context, state) =>
              TableBookingDetailScreen(bookingId: state.pathParameters['id']!),
        ),
      ],
      refreshListenable: authService, // Rebuild router when auth state changes
    );
  }
}
