import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/restaurant_model.dart';
import '../../../services/mock_data_service.dart';
import '../../../widgets/admin/admin_scaffold.dart';

/// Deep-linkable detail/edit screen for a table booking, mirroring
/// [BookingDetailScreen] on the beach side: `/admin/restaurant/bookings/:id`.
class TableBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const TableBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<TableBookingDetailScreen> createState() => _TableBookingDetailScreenState();
}

class _TableBookingDetailScreenState extends State<TableBookingDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _allergyController;
  bool _editingName = false;
  bool _editingAllergy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _allergyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/restaurant/bookings');
    }
  }

  void _update(BuildContext context, MockDataService data, TableBooking updated) {
    final error = data.updateTableBooking(updated);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final booking = data.tableBookings.where((b) => b.id == widget.bookingId).firstOrNull;

    if (booking == null) {
      return AdminScaffold(
        title: 'Prenotazione Tavolo',
        selectedIndex: -1,
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => _goBack(context)),
        ],
        child: const Center(child: Text('Prenotazione non trovata (potrebbe essere stata eliminata).')),
      );
    }

    final hasBeachBooking = data.userHasBeachBooking(booking.userId);

    return AdminScaffold(
      title: 'Prenotazione: ${booking.customerName}',
      selectedIndex: -1,
      actions: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => _goBack(context)),
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
              _buildInfoRow(Icons.table_restaurant, 'Tavolo', data.restaurantTableLabel(booking.tableId)),
              _buildInfoRow(Icons.calendar_today, 'Data',
                  '${DateFormat('EEEE d MMMM yyyy', 'it_IT').format(booking.date)} · ${booking.shift.label} (${booking.shift.timeRange})'),
              _buildInfoRow(Icons.people, 'Persone', '${booking.partySize}'),
              if (hasBeachBooking)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.beach_access, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Questo cliente ha anche una prenotazione ombrellone in spiaggia.')),
                  ]),
                ),
              _buildAllergyField(context, data, booking),
              _buildInfoRow(
                  booking.checkedIn ? Icons.check_circle : Icons.schedule,
                  'Check-in',
                  booking.checkedIn ? 'Cliente seduto' : 'In attesa di arrivo'),
              const Divider(height: 24),
              _buildInfoRow(Icons.euro, 'Conto', '€${booking.totalPrice.toStringAsFixed(2)}'),
              if (booking.deposit > 0)
                _buildInfoRow(Icons.payments, 'Acconto versato', '€${booking.deposit.toStringAsFixed(2)}'),
              if (booking.balanceDue > 0)
                _buildInfoRow(Icons.account_balance_wallet, 'Saldo da incassare',
                    '€${booking.balanceDue.toStringAsFixed(2)}'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stato Pagamento'),
                subtitle: Text(booking.isPaid ? 'Pagato' : 'Da Pagare'),
                value: booking.isPaid,
                activeThumbColor: Colors.green,
                secondary: Icon(booking.isPaid ? Icons.check_circle : Icons.warning,
                    color: booking.isPaid ? Colors.green : Colors.orange),
                onChanged: (v) => _update(context, data, booking.copyWith(isPaid: v)),
              ),
              const Divider(height: 32),
              if (!booking.checkedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => data.performTableCheckIn(booking.id),
                    icon: const Icon(Icons.login),
                    label: const Text('Segna Check-in'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showMoveDialog(context, data, booking),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambia Tavolo'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, data, booking),
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

  Widget _buildNameField(BuildContext context, MockDataService data, TableBooking booking) {
    if (!_editingName) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person, color: Colors.grey),
        title: const Text('Cliente', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(booking.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () {
            _nameController.text = booking.customerName;
            setState(() => _editingName = true);
          },
        ),
      );
    }
    return Row(
      children: [
        Expanded(child: TextField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Nome Cliente'))),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            _update(context, data, booking.copyWith(customerName: name));
            setState(() => _editingName = false);
          },
        ),
        IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _editingName = false)),
      ],
    );
  }

  Widget _buildAllergyField(BuildContext context, MockDataService data, TableBooking booking) {
    if (!_editingAllergy) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.warning_amber,
            color: (booking.allergyNotes?.isNotEmpty ?? false) ? Colors.red : Colors.grey),
        title: const Text('Allergie / Note', style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
            (booking.allergyNotes?.isNotEmpty ?? false) ? booking.allergyNotes! : 'Nessuna nota',
            style: const TextStyle(fontSize: 15)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () {
            _allergyController.text = booking.allergyNotes ?? '';
            setState(() => _editingAllergy = true);
          },
        ),
      );
    }
    return Row(
      children: [
        Expanded(
            child: TextField(
                controller: _allergyController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Allergie / Note'))),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () {
            _update(context, data, booking.copyWith(allergyNotes: _allergyController.text.trim()));
            setState(() => _editingAllergy = false);
          },
        ),
        IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _editingAllergy = false)),
      ],
    );
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

  void _showMoveDialog(BuildContext context, MockDataService data, TableBooking booking) {
    String? targetId;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Cambia tavolo'),
          content: DropdownButtonFormField<String>(
            initialValue: targetId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Nuovo tavolo'),
            items: data.restaurantTables
                .where((t) => t.id != booking.tableId)
                .map((t) => DropdownMenuItem(value: t.id, child: Text('Tavolo ${t.label} (${t.seats} posti)')))
                .toList(),
            onChanged: (v) => setLocal(() => targetId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: targetId == null
                  ? null
                  : () {
                      final error = data.updateTableBooking(booking.copyWith(tableId: targetId));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error ?? 'Tavolo cambiato!'),
                          backgroundColor: error == null ? Colors.green : Colors.red));
                    },
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MockDataService data, TableBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Eliminare questa prenotazione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              data.deleteTableBooking(booking.id);
              Navigator.pop(context);
              _goBack(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
