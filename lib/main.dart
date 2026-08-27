import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// Services
import 'services/mock_data_service.dart';
import 'services/auth_service.dart';

// Screens
import 'screens/user/extra_services_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/booking_screen.dart';
import 'screens/user/restaurant_booking_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/menu_order_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  runApp(const BeachBookingApp());
}

class BeachBookingApp extends StatelessWidget {
  const BeachBookingApp({super.key});

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
            title: 'Beach Booking',
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

        // Redirect to login if not authenticated and not already on login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // Redirect to home if authenticated and on login page
        if (isAuthenticated && isLoginRoute) {
          return '/';
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Customer Routes
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
      ],
      refreshListenable: authService, // Rebuild router when auth state changes
    );
  }
}
