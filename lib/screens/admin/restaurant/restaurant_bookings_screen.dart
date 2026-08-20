import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/restaurant_model.dart';
import '../../../services/mock_data_service.dart';
import '../../../widgets/admin/admin_scaffold.dart';

/// Operator list of restaurant table bookings, with a "+" to register a new
/// one (walk-in or phone booking) — the restaurant equivalent of
/// BookingsManagementScreen.
class RestaurantBookingsScreen extends StatefulWidget {
  const RestaurantBookingsScreen({super.key});

  @override
  State<RestaurantBookingsScreen> createState() => _RestaurantBookingsScreenState();
}

class _RestaurantBookingsScreenState extends State<RestaurantBookingsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    var bookings = [...data.tableBookings]..sort((a, b) => b.date.compareTo(a.date));
    if (_search.isNotEmpty) {
      bookings = bookings
          .where((b) => b.customerName.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    return AdminScaffold(
      title: 'Prenotazioni Ristorante',
      selectedIndex: 32,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Nuova prenotazione',
          onPressed: () => _showCreateDialog(context, data),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cerca per nome cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: bookings.isEmpty
                ? const Center(child: Text('Nessuna prenotazione', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final b = bookings[index];
                      final hasBeach = data.userHasBeachBooking(b.userId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade50,
                          child: Text(b.customerName.isNotEmpty ? b.customerName[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.brown.shade700, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(b.customerName),
                        subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(b.date)} · ${b.shift.label} · Tavolo ${data.restaurantTableLabel(b.tableId)} · ${b.partySize}p'
                            '${hasBeach ? ' · 🏖 anche spiaggia' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('€${b.totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: b.isPaid ? Colors.green : Colors.orange.shade800)),
                            const SizedBox(width: 8),
                            if (b.allergyNotes != null && b.allergyNotes!.isNotEmpty)
                              const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                            if (b.checkedIn)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.check_circle, color: Colors.teal, size: 18),
                              ),
                          ],
                        ),
                        onTap: () => context.push('/admin/restaurant/bookings/${b.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, MockDataService data) {
    final nameController = TextEditingController();
    final allergyController = TextEditingController();
    DateTime date = DateTime.now();
    RestaurantShift shift = RestaurantShift.cena;
    int partySize = 2;
    String? tableId;
    bool isPaid = false;
    final priceController =
        TextEditingController(text: (2 * data.restaurantCoverCharge).toStringAsFixed(2));
    bool priceEditedManually = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final available = data.restaurantTables
              .where((t) => t.seats >= partySize && data.isTableAvailable(t.id, date, shift))
              .toList();
          if (tableId != null && !available.any((t) => t.id == tableId)) {
            tableId = null;
          }
          return AlertDialog(
            title: const Text('Nuova Prenotazione Ristorante'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome Cliente', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today)),
                      child: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<RestaurantShift>(
                    segments: const [
                      ButtonSegment(value: RestaurantShift.pranzo, label: Text('Pranzo')),
                      ButtonSegment(value: RestaurantShift.cena, label: Text('Cena')),
                    ],
                    selected: {shift},
                    onSelectionChanged: (s) => setLocal(() => shift = s.first),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Persone:'),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: partySize > 1
                            ? () => setLocal(() {
                                  partySize--;
                                  if (!priceEditedManually) {
                                    priceController.text =
                                        (partySize * data.restaurantCoverCharge).toStringAsFixed(2);
                                  }
                                })
                            : null,
                      ),
                      Text('$partySize', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setLocal(() {
                          partySize++;
                          if (!priceEditedManually) {
                            priceController.text =
                                (partySize * data.restaurantCoverCharge).toStringAsFixed(2);
                          }
                        }),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: tableId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tavolo', prefixIcon: Icon(Icons.table_restaurant)),
                    items: available
                        .map((t) => DropdownMenuItem(value: t.id, child: Text('Tavolo ${t.label} (${t.seats} posti)')))
                        .toList(),
                    onChanged: (v) => setLocal(() => tableId = v),
                  ),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Nessun tavolo disponibile per questi criteri', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: allergyController,
                    decoration: const InputDecoration(labelText: 'Allergie / Note (opzionale)', prefixIcon: Icon(Icons.warning_amber)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Conto (€)', prefixIcon: Icon(Icons.euro)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => priceEditedManually = true,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Già Pagato'),
                    value: isPaid,
                    onChanged: (v) => setLocal(() => isPaid = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: tableId == null
                    ? null
                    : () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Inserisci il nome del cliente')));
                          return;
                        }
                        final booking = TableBooking(
                          id: const Uuid().v4(),
                          tableId: tableId!,
                          userId: 'manual_entry',
                          customerName: nameController.text.trim(),
                          date: date,
                          shift: shift,
                          partySize: partySize,
                          allergyNotes: allergyController.text.trim().isEmpty ? null : allergyController.text.trim(),
                          totalPrice: double.tryParse(priceController.text.replaceAll(',', '.')) ??
                              (partySize * data.restaurantCoverCharge),
                          isPaid: isPaid,
                        );
                        final error = data.addTableBooking(booking);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error ?? 'Prenotazione creata!'),
                            backgroundColor: error == null ? Colors.green : Colors.red));
                      },
                child: const Text('Crea'),
              ),
            ],
          );
        },
      ),
    );
  }
}
