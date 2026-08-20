import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/beach_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/mock_data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/user/booking_confirmation_ticket.dart';
import '../../utils/neumorphic_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  final List<String>? highlightBookingIds;

  const MyBookingsScreen({
    super.key,
    this.highlightBookingIds,
  });

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    // If there are highlighted bookings, show them after a short delay to allow UI to build
    if (widget.highlightBookingIds != null && widget.highlightBookingIds!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHighlightedBookings();
      });
    }
  }

  void _showHighlightedBookings() {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser == null) return;

    final userBookings = dataService.getUserBookings(authService.currentUser!.id);
    
    // Find the bookings to highlight
    final bookingsToShow = userBookings.where(
      (b) => widget.highlightBookingIds!.contains(b.id)
    ).toList();

    if (bookingsToShow.isEmpty) return;

    // Show the first one (showing multiple dialogs might be overwhelming, 
    // but for multi-booking we might want to show a summary or iterate?
    // Let's show the first one for now, or maybe a special "New Bookings" dialog?
    // The requirement says "open the relevant ticket". 
    // If multiple, maybe we just scroll to them? 
    // Or if it's a group booking, maybe we should have a "Group Ticket" view?
    // For now, let's open the first one found.
    
    final booking = bookingsToShow.first;
    final umbrella = dataService.umbrellas.firstWhere(
      (u) => u.id == booking.umbrellaId,
      orElse: () => dataService.umbrellas.first,
    );
    
    final package = dataService.packages.firstWhere(
      (p) => p.id == (booking.packageId ?? ''),
      orElse: () => dataService.packages.first,
    );

    _showBookingTicket(context, booking, umbrella, package, dataService);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dataService = Provider.of<MockDataService>(context);
    
    if (authService.currentUser == null) {
      return Scaffold(
        backgroundColor: NeumorphicTheme.background,
        appBar: AppBar(
          title: const Text('Le Mie Prenotazioni'),
          backgroundColor: NeumorphicTheme.background,
          elevation: 0,
        ),
        body: const Center(child: Text('Devi effettuare il login')),
      );
    }

    final userBookings = dataService.getUserBookings(authService.currentUser!.id);
    final tableBookings = dataService.getUserTableBookings(authService.currentUser!.id);
    // SliverFillRemaining claims the whole remaining viewport, so it must
    // only be used for the true empty state (nothing on either side) —
    // otherwise it pushes the restaurant-bookings section below the fold
    // even though there's real content to show right below it.
    final trulyEmpty = userBookings.isEmpty && tableBookings.isEmpty;

    return Scaffold(
      backgroundColor: NeumorphicTheme.background,
      body: CustomScrollView(
        slivers: [
          // Neumorphic App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: NeumorphicTheme.background,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_2, color: NeumorphicTheme.accent),
                tooltip: 'Importa codice sharing',
                onPressed: () => _showImportShareDialog(dataService, authService),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Le Mie Prenotazioni',
                style: TextStyle(
                  color: NeumorphicTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NeumorphicTheme.background,
                      NeumorphicTheme.background.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Service credit banner
          if (dataService.serviceCreditFor(authService.currentUser!.id) > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.teal.shade400,
                      Colors.green.shade500,
                    ]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Credito servizi disponibile',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '€${dataService.serviceCreditFor(authService.currentUser!.id).toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Content
          if (userBookings.isEmpty)
            trulyEmpty
                ? SliverFillRemaining(child: Center(child: _buildEmptyBeachState()))
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: _buildEmptyBeachState(compact: true),
                    ),
                  )
          else
            SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = userBookings[index];
                        final umbrella = dataService.umbrellas.firstWhere(
                          (u) => u.id == booking.umbrellaId,
                          orElse: () => dataService.umbrellas.first,
                        );
                        
                        final package = dataService.packages.firstWhere(
                          (p) => p.id == (booking.packageId ?? ''),
                          orElse: () => dataService.packages.first,
                        );

                        final isToday = DateTime.now().isAfter(booking.startDate.subtract(const Duration(days: 1))) &&
                            DateTime.now().isBefore(booking.endDate.add(const Duration(days: 1)));
                        
                        // Highlight if in the list
                        final isHighlighted = widget.highlightBookingIds?.contains(booking.id) ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildNeumorphicBookingCard(
                            context,
                            booking,
                            umbrella,
                            package,
                            isToday,
                            isHighlighted,
                            dataService,
                          ),
                        );
                      },
                      childCount: userBookings.length,
                    ),
                  ),
                ),
          SliverToBoxAdapter(
            child: _buildRestaurantBookingsSection(dataService, authService.currentUser!.id),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBeachState({bool compact = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 72 : 120,
          height: compact ? 72 : 120,
          decoration: NeumorphicTheme.pressed(),
          child: Icon(
            Icons.inbox_outlined,
            size: compact ? 36 : 60,
            color: NeumorphicTheme.textSecondary,
          ),
        ),
        SizedBox(height: compact ? 16 : 32),
        Text(
          compact ? 'Nessuna prenotazione spiaggia' : 'Nessuna prenotazione',
          style: TextStyle(
            fontSize: compact ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: NeumorphicTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Le tue prenotazioni appariranno qui',
          style: TextStyle(
            fontSize: 16,
            color: NeumorphicTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantBookingsSection(MockDataService dataService, String userId) {
    final tableBookings = dataService.getUserTableBookings(userId)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (tableBookings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prenotazioni Ristorante',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NeumorphicTheme.textPrimary)),
          const SizedBox(height: 16),
          ...tableBookings.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: NeumorphicTheme.elevated(),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: NeumorphicTheme.pressed(),
                        child: const Icon(Icons.table_restaurant, color: NeumorphicTheme.accent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tavolo ${dataService.restaurantTableLabel(b.tableId)} · ${b.partySize} persone',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                                '${DateFormat('dd/MM/yyyy').format(b.date)} · ${b.shift.label} (${b.shift.timeRange})',
                                style: const TextStyle(color: NeumorphicTheme.textSecondary, fontSize: 13)),
                            if (b.allergyNotes != null && b.allergyNotes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('⚠ ${b.allergyNotes}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      if (b.checkedIn)
                        const Icon(Icons.check_circle, color: Colors.teal),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNeumorphicBookingCard(
    BuildContext context,
    booking,
    umbrella,
    package,
    bool isToday,
    bool isHighlighted,
    MockDataService dataService,
  ) {
    final isMultiDay = booking.endDate.difference(booking.startDate).inDays >= 1;
    final isOwner = booking.sharedFromBookingId == null;

    return GestureDetector(
      onTap: () => _showBookingTicket(context, booking, umbrella, package, dataService),
      child: Container(
        decoration: isHighlighted
            ? NeumorphicTheme.elevated(color: Colors.blue.shade50) // Subtle highlight
            : NeumorphicTheme.elevated(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
            children: [
              // Neumorphic Umbrella Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: NeumorphicTheme.pressed(
                      color: isToday ? Colors.green.shade50 : NeumorphicTheme.background,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.beach_access,
                          color: isToday ? Colors.green.shade700 : NeumorphicTheme.accent,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dataService.umbrellaLabel(booking.umbrellaId),
                          style: TextStyle(
                          color: isToday ? Colors.green.shade700 : NeumorphicTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.isSeasonal || booking.isLastMinute)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Tooltip(
                        message: booking.isSeasonal ? 'Stagionale' : 'Last-minute',
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor:
                              booking.isSeasonal ? Colors.indigo : Colors.pinkAccent,
                          child: Icon(
                            booking.isSeasonal ? Icons.event_repeat : Icons.bolt,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Booking Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeumorphicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: NeumorphicTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: NeumorphicTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateRange(booking.startDate, booking.endDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: NeumorphicTheme.textSecondary,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'OGGI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price and QR Icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: NeumorphicTheme.pressed(),
                    child: const Icon(
                      Icons.qr_code,
                      color: NeumorphicTheme.accent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (booking.extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (booking.extras as List<BookingExtra>).map((e) {
                final daysLabel = e.isPartialStay ? ' · ${e.forDates!.length} gg' : '';
                return Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(e.isService ? Icons.room_service : Icons.chair, size: 14),
                  label: Text('${e.quantity}× ${e.name}$daysLabel',
                      style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
          ],
          if (isMultiDay && isOwner) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showAbsenceDialog(booking, dataService),
                    icon: const Icon(Icons.event_busy, size: 18),
                    label: const Text('Assenza'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.deepOrange),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showShareDialog(booking, dataService),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Condividi'),
                    style: TextButton.styleFrom(
                        foregroundColor: NeumorphicTheme.accent),
                  ),
                ),
              ],
            ),
          ],
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.blue.shade400),
                  const SizedBox(width: 6),
                  Text('Postazione condivisa con te',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue.shade400)),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  List<DateTime> _daysOf(Booking b) {
    final days = <DateTime>[];
    var d = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
    final end = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  void _showAbsenceDialog(Booking booking, MockDataService dataService) {
    final days = _daysOf(booking);
    final selected = <DateTime>{};
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Segnala assenza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Seleziona i giorni in cui sarai assente: la postazione potrà essere rivenduta. '
                  'Se segnali almeno 24h prima, ricevi un credito servizi del 30% per ogni giorno.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: days.map((d) {
                  final already = booking.isAbsentOn(d);
                  final sel = selected.contains(d);
                  return FilterChip(
                    label: Text(DateFormat('dd/MM').format(d)),
                    selected: sel || already,
                    onSelected: already
                        ? null
                        : (v) => setLocal(() {
                              if (v) {
                                selected.add(d);
                              } else {
                                selected.remove(d);
                              }
                            }),
                    disabledColor: Colors.orange.shade100,
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      double credit = 0;
                      for (final d in selected) {
                        credit += dataService.markAbsence(booking.id, d);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(credit > 0
                              ? 'Assenza registrata. Credito servizi accumulato: €${credit.toStringAsFixed(2)}'
                              : 'Assenza registrata (nessun credito: preavviso inferiore a 24h)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(Booking booking, MockDataService dataService) {
    DateTime start = booking.startDate;
    DateTime end = booking.endDate;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Condividi la postazione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Scegli il periodo da condividere. Genererai un codice univoco da inviare '
                  'a un\'altra persona, che potrà importarlo nella sua app.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _miniDate('Dal', start, booking.startDate,
                        booking.endDate, (d) => setLocal(() {
                      start = d;
                      if (end.isBefore(start)) end = start;
                    })),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniDate('Al', end, start, booking.endDate,
                        (d) => setLocal(() => end = d)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final code =
                    dataService.shareBooking(booking.id, start, end);
                Navigator.pop(context);
                _showGeneratedCode(code);
              },
              child: const Text('Genera codice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniDate(String label, DateTime value, DateTime first, DateTime last,
      Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder(), isDense: true),
        child: Text(DateFormat('dd/MM/yyyy').format(value)),
      ),
    );
  }

  void _showGeneratedCode(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.qr_code_2, size: 40, color: Colors.blue),
        title: const Text('Codice sharing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invia questo codice alla persona con cui condividi:'),
            const SizedBox(height: 16),
            SelectableText(code,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Codice copiato')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copia'),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chiudi')),
        ],
      ),
    );
  }

  void _showImportShareDialog(
      MockDataService dataService, AuthService authService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa codice sharing'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Codice (es. SH-AB12CD)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code_2),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final user = authService.currentUser;
              if (user == null) return;
              final error = dataService.importShare(
                  controller.text, user.id, user.name);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Postazione importata con successo!'),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }

  void _showBookingTicket(
    BuildContext context,
    booking,
    umbrella,
    package,
    MockDataService dataService,
  ) {
    showDialog(
      context: context,
      builder: (context) => BookingConfirmationTicket(
        bookingId: booking.id,
        umbrella: umbrella,
        startDate: booking.startDate,
        endDate: booking.endDate,
        customerName: booking.customerName,
        packageName: package.name,
        subtotal: booking.subtotal > 0 ? booking.subtotal : booking.totalPrice,
        bookingFee: booking.bookingFee,
        vat: booking.vat,
        paymentFee: booking.paymentFee,
        total: booking.totalPrice,
        extras: booking.extras,
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }
}
