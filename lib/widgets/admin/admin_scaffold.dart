
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data_service.dart';
import 'notifications_panel.dart';



class AdminScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final int selectedIndex;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.selectedIndex,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Row(
          children: [
            // Sidebar
            _buildSidebar(context),
            
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // App Bar (Custom)
                  _buildAppBar(context),
                  
                  // Content Body
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 24, bottom: 24, left: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
          Consumer<MockDataService>(
            builder: (context, data, _) {
              final unread = data.unreadNotificationsCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => showNotificationsPanel(context),
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    tooltip: 'Notifiche',
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final role = Provider.of<AuthService>(context).currentUser?.role;
    final isRestaurantManager = role == UserRole.restaurantManager;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      color: Colors.transparent,
      child: Column(
        children: [
          // Logo Area
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    isRestaurantManager ? Icons.restaurant : Icons.beach_access,
                    color: Colors.blue.shade700,
                    size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isRestaurantManager ? 'Restaurant Manager' : 'Beach Manager',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Navigation Items — a restaurant manager only ever sees their
          // own section (confined there by main.dart's role redirect too);
          // a beach manager sees the full beach admin but not the
          // restaurant's own management screens (they only get a
          // cross-reference badge on bookings, not access to manage it).
          Expanded(
            child: ListView(
              children: isRestaurantManager
                  ? [
                      _buildNavItem(context, 30, Icons.dashboard_customize, 'Dashboard Ristorante',
                          () => _navigate(context, 30)),
                      _buildNavItem(
                          context, 31, Icons.table_restaurant, 'Editor Mappa Tavoli', () => _navigate(context, 31)),
                      _buildNavItem(
                          context, 32, Icons.event_seat, 'Prenotazioni Ristorante', () => _navigate(context, 32)),
                    ]
                  : [
                      _buildNavItem(context, 0, Icons.dashboard, 'Dashboard', () => _navigate(context, 0)),
                      _buildNavItem(context, 1, Icons.qr_code_scanner, 'Scansiona QR', () => _navigate(context, 1)),
                      _buildNavItem(context, 2, Icons.map, 'Editor Mappa', () => _navigate(context, 2)),
                      _buildNavItem(context, 3, Icons.price_change, 'Listini & Prezzi', () => _navigate(context, 3)),
                      _buildNavItem(context, 4, Icons.room_service, 'Servizi Extra', () => _navigate(context, 4)),
                      _buildNavItemWithBadge(context, 40, Icons.shopping_bag, 'Ordini Extra',
                          () => _navigate(context, 40), Provider.of<MockDataService>(context).pendingExtraOrdersCount),
                      _buildNavItem(context, 5, Icons.restaurant, 'Bar & Ordini', () => _navigate(context, 5)),
                      _buildNavItem(context, 20, Icons.menu_book, 'Gestione Menu', () => _navigate(context, 20)),
                      _buildNavItem(
                          context, 6, Icons.calendar_month, 'Calendario Planner', () => _navigate(context, 6)),
                      _buildNavItem(
                          context, 7, Icons.account_balance_wallet, 'Contabilità', () => _navigate(context, 7)),
                    ],
            ),
          ),

          // Logout
          _buildNavItem(context, -1, Icons.logout, 'Logout', () {
             Provider.of<AuthService>(context, listen: false).logout();
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildNavItemWithBadge(
      BuildContext context, int index, IconData icon, String label, VoidCallback onTap, int badgeCount) {
    return Stack(
      children: [
        _buildNavItem(context, index, icon, label, onTap),
        if (badgeCount > 0)
          Positioned(
            right: 12,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, VoidCallback onTap, {bool isLogout = false}) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isLogout ? Colors.redAccent.shade100 : Colors.white, 
                  size: 24
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isLogout ? Colors.redAccent.shade100 : Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
      if (index == selectedIndex) return;

      switch (index) {
        case 0:
          context.go('/admin/dashboard');
          break;
        case 1:
          context.go('/admin/scan');
          break;
        case 2:
          context.go('/admin/map');
          break;
        case 3:
          context.go('/admin/pricing');
          break;
        case 4:
          context.go('/admin/extras');
          break;
        case 5:
          context.go('/admin/orders');
          break;
        case 6:
           context.go('/admin/bookings');
           break;
        case 7:
           context.go('/admin/financial');
           break;
        case 8:
           context.go('/admin/daily-map');
           break;
        case 30:
           context.go('/admin/restaurant/dashboard');
           break;
        case 31:
           context.go('/admin/restaurant/map');
           break;
        case 32:
           context.go('/admin/restaurant/bookings');
           break;
        case 20:
           context.go('/admin/menu');
           break;
        case 40:
           context.go('/admin/extra-orders');
           break;
      }
  }
}

