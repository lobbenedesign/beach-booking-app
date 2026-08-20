import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/beach_model.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/admin/admin_scaffold.dart';

/// Dedicated, deep-linkable screen for a single booking (`/admin/bookings/:id`).
/// Lets the operator view every detail and edit the customer name, the date
/// range, extras, payment/status, or move/delete the booking — replacing the
/// old `BookingDetailDialog` so a booking has a real address in the app
/// instead of only a modal.
class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final TextEditingController _nameController;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final booking =
        data.bookings.where((b) => b.id == widget.bookingId).firstOrNull;

    if (booking == null) {
      return AdminScaffold(
        title: 'Prenotazione',
        selectedIndex: -1,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _goBack(context),
          ),
        ],
        child: const Center(
          child: Text('Prenotazione non trovata (potrebbe essere stata eliminata).'),
        ),
      );
    }

    final umbrella = data.umbrellas.where((u) => u.id == booking.umbrellaId).firstOrNull;
    final hasRestaurantBooking = data.userHasRestaurantBooking(booking.userId);

    return AdminScaffold(
      title: 'Prenotazione: ${booking.customerName}',
      selectedIndex: -1,
      actions: [
        if (booking.isSeasonal)
          const Tooltip(
            message: 'Stagionale',
            child: Icon(Icons.event_repeat, color: Colors.white),
          ),
        if (booking.isLastMinute)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Tooltip(
              message: 'Last-minute',
              child: Icon(Icons.bolt, color: Colors.white),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _goBack(context),
          tooltip: 'Torna indietro',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(context, data, booking),
              const SizedBox(height: 8),
              if (hasRestaurantBooking)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.restaurant, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Questo cliente ha anche una prenotazione al ristorante.')),
                  ]),
                ),
              _buildDateField(context, data, booking),
              _buildInfoRow(Icons.beach_access, 'Ombrellone',
                  umbrella?.label ?? '${umbrella?.row}-${umbrella?.number}'),
              _buildInfoRow(Icons.euro, 'Prezzo', '€${booking.totalPrice.toStringAsFixed(2)}'),
              if (booking.isDeposit)
                _buildInfoRow(Icons.payments, 'Acconto versato',
                    '€${booking.deposit.toStringAsFixed(2)}'),
              if (booking.balanceDue > 0)
                _buildInfoRow(Icons.account_balance_wallet, 'Saldo da incassare',
                    '€${booking.balanceDue.toStringAsFixed(2)}'),
              if (booking.couponCode != null)
                _buildInfoRow(Icons.local_offer, 'Coupon',
                    '${booking.couponCode} (-€${booking.discountAmount.toStringAsFixed(2)})'),
              _buildInfoRow(
                  booking.checkedOut
                      ? Icons.logout
                      : (booking.checkedIn ? Icons.login : Icons.schedule),
                  'Check-in',
                  booking.checkedOut
                      ? 'Check-out effettuato'
                      : (booking.checkedIn ? 'Cliente presente' : 'In attesa di arrivo')),

              const Divider(height: 32),
              _buildExtrasSection(context, data, booking),
              const Divider(height: 32),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stato Pagamento'),
                subtitle: Text(booking.isPaid ? 'Pagato' : 'Da Pagare in Struttura'),
                value: booking.isPaid,
                activeThumbColor: Colors.green,
                secondary: Icon(
                  booking.isPaid ? Icons.check_circle : Icons.warning,
                  color: booking.isPaid ? Colors.green : Colors.orange,
                ),
                onChanged: (val) => _update(context, data, booking.copyWith(isPaid: val)),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('Stato Prenotazione'),
                trailing: DropdownButton<BookingStatus>(
                  value: booking.status,
                  items: BookingStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _update(context, data, booking.copyWith(status: val));
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showMoveDialog(context, data, booking),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Sposta / Rivendi'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _deleteBooking(context, data, booking),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(BuildContext context, MockDataService data, Booking booking) {
    if (!_editingName) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person, color: Colors.grey),
        title: const Text('Cliente', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(booking.customerName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Modifica nome',
          onPressed: () {
            _nameController.text = booking.customerName;
            setState(() => _editingName = true);
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome Cliente'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              _update(context, data, booking.copyWith(customerName: name));
              setState(() => _editingName = false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() => _editingName = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, MockDataService data, Booking booking) {
    final period =
        '${DateFormat('dd/MM').format(booking.startDate)} - ${DateFormat('dd/MM/yyyy').format(booking.endDate)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, color: Colors.grey),
      title: const Text('Periodo', style: TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(period, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18),
        tooltip: 'Modifica date',
        onPressed: () => _pickDates(context, data, booking),
      ),
    );
  }

  Future<void> _pickDates(BuildContext context, MockDataService data, Booking booking) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: booking.startDate, end: booking.endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !context.mounted) return;
    _update(context, data,
        booking.copyWith(startDate: picked.start, endDate: picked.end));
  }

  void _update(BuildContext context, MockDataService data, Booking updated) {
    final error = data.updateBooking(updated);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasSection(BuildContext context, MockDataService data, Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.add_shopping_cart, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            const Text('Extra', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddExtraDialog(context, data, booking),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Aggiungi'),
            ),
          ],
        ),
        if (booking.extras.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 32, bottom: 4),
            child: Text('Nessun extra aggiunto', style: TextStyle(color: Colors.grey)),
          )
        else
          ...booking.extras.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final daysLabel = e.isPartialStay
                ? '${e.forDates!.length} gg (${e.forDates!.map((d) => DateFormat('dd/MM').format(d)).join(', ')})'
                : 'tutto il soggiorno';
            return Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${e.quantity}× ${e.name} · $daysLabel',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                      '€${(e.price * e.quantity * (e.forDates?.length ?? booking.durationInDays)).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => data.removeExtraFromBooking(booking.id, i),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddExtraDialog(BuildContext context, MockDataService data, Booking booking) {
    final equipment = data.extraEquipment;
    final services = data.extraServices;
    final all = <dynamic>[...equipment, ...services];
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun extra configurato')),
      );
      return;
    }

    final days = List.generate(
      booking.durationInDays,
      (i) => booking.startDate.add(Duration(days: i)),
    );

    dynamic selected = all.first;
    final selectedDays = <DateTime>{};
    bool allDays = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Aggiungi Extra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<dynamic>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Extra'),
                  items: all
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.name} (€${e.price.toStringAsFixed(2)}/giorno)'),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selected = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tutto il soggiorno'),
                  value: allDays,
                  onChanged: (v) => setLocal(() => allDays = v),
                ),
                if (!allDays)
                  Wrap(
                    spacing: 6,
                    children: days.map((d) {
                      final on = selectedDays.contains(d);
                      return FilterChip(
                        label: Text(DateFormat('dd/MM').format(d)),
                        selected: on,
                        onSelected: (v) => setLocal(() {
                          if (v) {
                            selectedDays.add(d);
                          } else {
                            selectedDays.remove(d);
                          }
                        }),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: (!allDays && selectedDays.isEmpty)
                  ? null
                  : () {
                      final isService = selected is ExtraService;
                      final error = data.addExtraToBooking(
                        bookingId: booking.id,
                        id: selected.id,
                        name: selected.name,
                        price: selected.price,
                        isService: isService,
                        forDates: allDays ? null : selectedDays.toList(),
                      );
                      Navigator.pop(context);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.red),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Extra aggiunto, totale aggiornato'),
                              backgroundColor: Colors.green),
                        );
                      }
                    },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, MockDataService data, Booking booking) {
    final umbrellas = data.umbrellas;
    String? targetId;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Sposta / Rivendi prenotazione'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ombrellone attuale: ${data.umbrellaLabel(booking.umbrellaId)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: targetId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nuovo ombrellone'),
                items: umbrellas
                    .where((u) => u.id != booking.umbrellaId)
                    .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('Ombrellone ${u.label ?? '${u.row}-${u.number}'}'),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => targetId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: targetId == null
                  ? null
                  : () {
                      final error = data.moveBooking(booking.id, targetId!);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Prenotazione spostata!'),
                          backgroundColor: error == null ? Colors.green : Colors.red,
                        ),
                      );
                    },
              child: const Text('Sposta'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBooking(BuildContext context, MockDataService data, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa prenotazione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              data.deleteBooking(booking.id);
              Navigator.pop(context); // confirm dialog
              _goBack(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prenotazione eliminata')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
