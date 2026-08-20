import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../services/mock_data_service.dart';

/// Reproduces the restaurant floor plan with live table-booking state for a
/// selected day/shift — the restaurant equivalent of [BeachMapLiveView].
/// Free tables are green, booked ones blue (orange once checked-in), tap a
/// booked table to jump to its detail screen.
class RestaurantTableMapLiveView extends StatelessWidget {
  final DateTime date;
  final RestaurantShift shift;

  const RestaurantTableMapLiveView({
    super.key,
    required this.date,
    required this.shift,
  });

  static const Color _free = Color(0xFF4CAF50);
  static const Color _booked = Color(0xFF1E88E5);
  static const Color _seated = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final tables = data.restaurantTables;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFFBF3E7),
        // SizedBox.expand forces tight constraints on the LayoutBuilder: a
        // Stack made up entirely of Positioned children collapses to zero
        // size under loose constraints.
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  for (final t in tables) ..._buildTable(context, data, t, w, h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTable(
      BuildContext context, MockDataService data, RestaurantTable t, double w, double h) {
    final bookings = data.tableBookingsFor(t.id, date, shift);
    final booking = bookings.firstOrNull;
    final color = booking == null
        ? _free
        : (booking.checkedIn ? _seated : _booked);
    final size = t.width * w;
    final isRound = t.shape == TableShape.round;

    final marker = Positioned(
      left: t.x * w,
      top: t.y * h,
      child: Tooltip(
        message: booking == null
            ? 'Tavolo ${t.label} · ${t.seats} posti · Libero'
            : 'Tavolo ${t.label} · ${booking.customerName} · ${booking.partySize} persone'
                '${booking.allergyNotes != null && booking.allergyNotes!.isNotEmpty ? '\n⚠ ${booking.allergyNotes}' : ''}',
        child: GestureDetector(
          onTap: booking == null
              ? null
              : () => context.push('/admin/restaurant/bookings/${booking.id}'),
          child: Container(
            width: size,
            height: t.height * h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isRound ? 999 : 8),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_restaurant, color: color, size: size * 0.4),
                Text(t.label ?? '', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    if (booking == null) return [marker];

    return [
      marker,
      Positioned(
        left: (t.x * w) - 10,
        top: (t.y * h) - 14,
        child: IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            child: Text(
              '${booking.customerName.split(' ').first} · ${booking.partySize}p',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      if (booking.allergyNotes != null && booking.allergyNotes!.isNotEmpty)
        Positioned(
          left: (t.x * w) + size - 6,
          top: (t.y * h) - 6,
          child: const IgnorePointer(
            child: CircleAvatar(
              radius: 7,
              backgroundColor: Colors.red,
              child: Icon(Icons.warning, size: 9, color: Colors.white),
            ),
          ),
        ),
    ];
  }
}

class RestaurantMapLegend extends StatelessWidget {
  const RestaurantMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _chip(RestaurantTableMapLiveView._free, 'Libero'),
        _chip(RestaurantTableMapLiveView._booked, 'Prenotato'),
        _chip(RestaurantTableMapLiveView._seated, 'Seduto (check-in)'),
        _iconChip(Colors.red, Icons.warning, 'Note allergie'),
      ],
    );
  }

  Widget _chip(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _iconChip(Color color, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 7, backgroundColor: color, child: Icon(icon, size: 9, color: Colors.white)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
