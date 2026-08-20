import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/beach_model.dart';
import '../../services/mock_data_service.dart';
import '../map/map_element_renderer.dart';
import '../map/beach_background_layer.dart';

/// Aggregate occupancy of a single umbrella over the selected date/range,
/// used to pick a marker color and build the tooltip/label.
enum RangeSpotStatus { free, booked, partial, absentResellable }

const Map<RangeSpotStatus, Color> spotStatusColors = {
  RangeSpotStatus.free: Color(0xFF4CAF50),
  RangeSpotStatus.booked: Color(0xFF1E88E5),
  RangeSpotStatus.partial: Color(0xFFFFB300),
  RangeSpotStatus.absentResellable: Color(0xFF8E24AA),
};

const Map<RangeSpotStatus, String> spotStatusLabels = {
  RangeSpotStatus.free: 'Libera',
  RangeSpotStatus.booked: 'Occupata',
  RangeSpotStatus.partial: 'Parzialmente occupata',
  RangeSpotStatus.absentResellable: 'Assente · rivendibile',
};

/// Reproduces the beach layout (same rendering used by the map editor and
/// the customer booking screen) and overlays live booking state for a
/// selected day or date range. Used by both the operator Dashboard and the
/// dedicated "Mappa Giornaliera" screen so the two stay visually and
/// functionally identical.
class BeachMapLiveView extends StatelessWidget {
  final DateTime rangeStart;
  final DateTime rangeEnd;

  /// Shows a price tag with the packages on sale on each free umbrella
  /// (derived from its zone's price list). Defaults to on.
  final bool showPackages;

  const BeachMapLiveView({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    this.showPackages = true,
  });

  bool get _isSingleDay => _isSameDay(rangeStart, rangeEnd);

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final hasCustomBg = data.beachBackgroundImage != null;
    final elements = data.mapElements
        .where((e) => !hasCustomBg || (e.type != MapElementType.sand && e.type != MapElementType.sea))
        .toList();
    final ordered = [...elements]..sort((a, b) => _z(a.type).compareTo(_z(b.type)));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFEAF4FB),
        // SizedBox.expand forces tight constraints on the LayoutBuilder: a
        // Stack made up entirely of Positioned children collapses to zero
        // size under loose constraints, so without this the whole map
        // silently renders at zero size whenever an ancestor (e.g. a Row's
        // default center cross-axis alignment) only offers a loose bound.
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  BeachBackgroundLayer(backgroundImageDataUrl: data.beachBackgroundImage),
                  for (final el in ordered)
                    if (el.type == MapElementType.umbrella)
                      ..._buildUmbrella(context, data, el, w, h)
                    else
                      _buildStaticElement(el, w, h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStaticElement(MapElement el, double w, double h) {
    return Positioned(
      left: el.x * w,
      top: el.y * h,
      child: SizedBox(
        width: el.width * w,
        height: el.height * h,
        child: _transformed(el, mapElementVisual(el, showUmbrellaLabel: false)),
      ),
    );
  }

  List<Widget> _buildUmbrella(
      BuildContext context, MockDataService data, MapElement el, double w, double h) {
    final bookings = data.bookingsForUmbrellaInRange(el.id, rangeStart, rangeEnd);
    final status = _statusFor(bookings);
    final color = spotStatusColors[status]!;
    final size = el.width * w;
    final primaryBooking = bookings.isNotEmpty ? bookings.first : null;

    final marker = Positioned(
      left: el.x * w,
      top: el.y * h,
      child: Tooltip(
        richMessage: _tooltipFor(data, el, bookings, status),
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => _handleTap(context, data, el, bookings),
          child: Container(
            width: size,
            height: el.height * h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color, width: 2),
            ),
            child: _transformed(
                el,
                mapElementVisual(
                  MapElement(
                    id: el.id,
                    type: el.type,
                    x: el.x,
                    y: el.y,
                    width: el.width,
                    height: el.height,
                    color: color,
                    row: el.row,
                    number: el.number,
                  ),
                  showUmbrellaLabel: false,
                )),
          ),
        ),
      ),
    );

    final widgets = <Widget>[marker];

    if (primaryBooking != null) {
      final pkg = data.packages
          .where((p) => p.id == primaryBooking.packageId)
          .firstOrNull;
      final extrasCount =
          primaryBooking.extras.fold<int>(0, (s, e) => s + e.quantity);
      final firstName = primaryBooking.customerName.split(' ').first;
      final label = [
        bookings.length > 1 ? '$firstName +${bookings.length - 1}' : firstName,
        if (pkg != null) pkg.name,
        if (extrasCount > 0) '+$extrasCount extra',
      ].join(' · ');

      widgets.add(Positioned(
        left: (el.x * w) - 20,
        top: (el.y * h) - 16,
        child: IgnorePointer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ));

      // Check-in dot (only meaningful when "today" is part of the selection).
      final coversToday = !DateTime.now().isBefore(rangeStart.subtract(const Duration(days: 1))) &&
          !DateTime.now().isAfter(rangeEnd);
      if (coversToday) {
        final todaysBooking = data.bookingForUmbrellaOn(el.id, DateTime.now());
        if (todaysBooking != null && todaysBooking.checkedIn) {
          widgets.add(Positioned(
            left: (el.x * w) + size - 6,
            top: (el.y * h) - 6,
            child: const IgnorePointer(
              child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.check, size: 10, color: Colors.teal)),
            ),
          ));
        }
      }

      // Seasonal / last-minute badge (bottom-right corner of the marker).
      if (primaryBooking.isSeasonal || primaryBooking.isLastMinute) {
        widgets.add(Positioned(
          left: (el.x * w) + size - 8,
          top: (el.y * h) + (el.height * h) - 8,
          child: IgnorePointer(
            child: CircleAvatar(
              radius: 8,
              backgroundColor: primaryBooking.isSeasonal
                  ? Colors.indigo
                  : Colors.pinkAccent,
              child: Icon(
                primaryBooking.isSeasonal ? Icons.event_repeat : Icons.bolt,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ));
      }
    } else if (showPackages) {
      final packages = data.packagesForUmbrella(el.id);
      if (packages.isNotEmpty) {
        final prices = packages
            .map((p) => data.priceForPackageOnUmbrella(p.id, el.id, rangeStart))
            .toList()
          ..sort();
        widgets.add(Positioned(
          left: (el.x * w) - 12,
          top: (el.y * h) + (el.height * h) - 2,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.green.shade400),
              ),
              child: Text(
                'da €${prices.first.toStringAsFixed(0)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ));
      }
    }

    return widgets;
  }

  RangeSpotStatus _statusFor(List<Booking> bookings) {
    if (bookings.isEmpty) return RangeSpotStatus.free;
    if (_isSingleDay && bookings.length == 1 && bookings.first.isAbsentOn(rangeStart)) {
      return RangeSpotStatus.absentResellable;
    }
    final coversWhole = bookings.length == 1 &&
        !bookings.first.startDate.isAfter(rangeStart) &&
        !bookings.first.endDate.isBefore(rangeEnd);
    return coversWhole ? RangeSpotStatus.booked : RangeSpotStatus.partial;
  }

  InlineSpan _tooltipFor(MockDataService data, MapElement el,
      List<Booking> bookings, RangeSpotStatus status) {
    final label = data.umbrellaLabel(el.id);
    if (bookings.isEmpty) {
      final packages = data.packagesForUmbrella(el.id);
      if (packages.isEmpty) {
        return TextSpan(text: 'Postazione $label\nLibera nel periodo selezionato');
      }
      final lines = ['Postazione $label · Libera', 'Pacchetti in vendita:'];
      for (final p in packages) {
        final price = data.priceForPackageOnUmbrella(p.id, el.id, rangeStart);
        lines.add('· ${p.name} — €${price.toStringAsFixed(0)}/giorno');
      }
      return TextSpan(text: lines.join('\n'));
    }
    final lines = <String>['Postazione $label · ${spotStatusLabels[status]}'];
    for (final b in bookings) {
      final period =
          '${DateFormat('dd/MM').format(b.startDate)}-${DateFormat('dd/MM').format(b.endDate)}';
      final channel = b.channel == BookingChannel.onSite ? 'in sede' : 'online';
      final tags = [
        if (b.isSeasonal) 'stagionale',
        if (b.isLastMinute) 'last-minute',
        if (b.checkedIn) 'check-in ok',
        if (b.isPaid) 'pagato' else 'da pagare',
        if (data.userHasRestaurantBooking(b.userId)) 'anche ristorante',
      ].join(', ');
      lines.add('${b.customerName} · $period · $channel${tags.isNotEmpty ? ' · $tags' : ''}');
    }
    return TextSpan(text: lines.join('\n'));
  }

  void _handleTap(BuildContext context, MockDataService data, MapElement el,
      List<Booking> bookings) {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Postazione ${data.umbrellaLabel(el.id)} libera nel periodo selezionato'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    if (bookings.length == 1) {
      _openBookingDetail(context, data, bookings.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Prenotazioni · Ombrellone ${data.umbrellaLabel(el.id)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...bookings.map((b) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(b.customerName),
                  subtitle: Text(
                      '${DateFormat('dd/MM').format(b.startDate)} - ${DateFormat('dd/MM/yyyy').format(b.endDate)}'),
                  onTap: () {
                    Navigator.pop(context);
                    _openBookingDetail(context, data, b);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _openBookingDetail(BuildContext context, MockDataService data, Booking booking) {
    context.push('/admin/bookings/${booking.id}');
  }

  Widget _transformed(MapElement el, Widget child) {
    Widget v = child;
    if (el.scaleX != 1.0 || el.scaleY != 1.0) {
      v = Transform.scale(scaleX: el.scaleX, scaleY: el.scaleY, child: v);
    }
    if (el.flipHorizontal || el.flipVertical) {
      v = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(el.flipHorizontal ? -1.0 : 1.0, el.flipVertical ? -1.0 : 1.0),
        child: v,
      );
    }
    if (el.rotation != 0) {
      v = Transform.rotate(angle: el.rotation * (3.14159 / 180), child: v);
    }
    return v;
  }

  int _z(MapElementType t) {
    switch (t) {
      case MapElementType.sea:
      case MapElementType.sand:
      case MapElementType.grass:
      case MapElementType.walkway:
      case MapElementType.rock:
        return 0;
      case MapElementType.zone:
        return 1;
      case MapElementType.umbrella:
        return 3;
      default:
        return 2;
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Shared legend for [BeachMapLiveView], usable both on the Dashboard and
/// the Mappa Giornaliera screen.
class BeachMapLegend extends StatelessWidget {
  const BeachMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        ...spotStatusColors.entries.map((e) => _chip(e.value, spotStatusLabels[e.key]!)),
        _iconChip(Colors.indigo, Icons.event_repeat, 'Stagionale'),
        _iconChip(Colors.pinkAccent, Icons.bolt, 'Last-minute'),
        _iconChip(Colors.teal, Icons.check, 'Check-in effettuato'),
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
