import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/restaurant_model.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data_service.dart';

/// Customer-facing table booking flow: pick date/shift/party size, see the
/// tables that actually fit, confirm with optional allergy notes. Mirrors
/// the spirit of the beach [BookingScreen] but simpler (no umbrella-style
/// locks) — the bill is a per-person cover charge (coperto), settled at the
/// table like a typical restaurant, not prepaid online.
class RestaurantBookingScreen extends StatefulWidget {
  const RestaurantBookingScreen({super.key});

  @override
  State<RestaurantBookingScreen> createState() => _RestaurantBookingScreenState();
}

class _RestaurantBookingScreenState extends State<RestaurantBookingScreen> {
  DateTime _date = DateTime.now();
  RestaurantShift _shift = RestaurantShift.cena;
  int _partySize = 2;
  RestaurantTable? _selectedTable;
  final _allergyController = TextEditingController();

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final available = data.restaurantTables
        .where((t) => t.seats >= _partySize && data.isTableAvailable(t.id, _date, _shift))
        .toList()
      ..sort((a, b) => a.seats.compareTo(b.seats));
    if (_selectedTable != null && !available.any((t) => t.id == _selectedTable!.id)) {
      _selectedTable = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Prenota il Tavolo')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedTable = null);
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Data', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
              child: Text(DateFormat('EEEE d MMMM yyyy', 'it_IT').format(_date)),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<RestaurantShift>(
            segments: [
              ButtonSegment(value: RestaurantShift.pranzo, label: Text('Pranzo\n${RestaurantShift.pranzo.timeRange}', textAlign: TextAlign.center)),
              ButtonSegment(value: RestaurantShift.cena, label: Text('Cena\n${RestaurantShift.cena.timeRange}', textAlign: TextAlign.center)),
            ],
            selected: {_shift},
            onSelectionChanged: (s) => setState(() {
              _shift = s.first;
              _selectedTable = null;
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Numero di persone:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _partySize > 1
                    ? () => setState(() {
                          _partySize--;
                          _selectedTable = null;
                        })
                    : null,
              ),
              Text('$_partySize', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() {
                  _partySize++;
                  _selectedTable = null;
                }),
              ),
            ],
          ),
          Center(
            child: Text(
              'Conto stimato: €${(_partySize * data.restaurantCoverCharge).toStringAsFixed(2)} '
              '(coperto €${data.restaurantCoverCharge.toStringAsFixed(2)}/persona)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tavoli disponibili', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Nessun tavolo disponibile per questi criteri.\nProva un altro turno o data.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: available.map((t) {
                final selected = _selectedTable?.id == t.id;
                return ChoiceChip(
                  label: Text('Tavolo ${t.label} · ${t.seats} posti'),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTable = t),
                  avatar: const Icon(Icons.table_restaurant, size: 18),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _allergyController,
            decoration: const InputDecoration(
              labelText: 'Allergie o note per la cucina (opzionale)',
              prefixIcon: Icon(Icons.warning_amber),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/menu'),
            icon: const Icon(Icons.menu_book),
            label: const Text('Consulta il menu'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _selectedTable == null ? null : () => _confirm(context, data),
            icon: const Icon(Icons.check_circle),
            label: const Text('Conferma Prenotazione'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, MockDataService data) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Conferma i tuoi dati'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome per la prenotazione'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final booking = TableBooking(
                id: const Uuid().v4(),
                tableId: _selectedTable!.id,
                userId: user?.id ?? 'guest',
                customerName: nameController.text.trim().isEmpty ? 'Cliente' : nameController.text.trim(),
                date: _date,
                shift: _shift,
                partySize: _partySize,
                allergyNotes: _allergyController.text.trim().isEmpty ? null : _allergyController.text.trim(),
                totalPrice: _partySize * data.restaurantCoverCharge,
              );
              final error = data.addTableBooking(booking);
              Navigator.pop(context);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Prenotazione tavolo confermata!'), backgroundColor: Colors.green));
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }
}
