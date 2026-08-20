import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/beach_model.dart';
import '../../services/mock_data_service.dart';

class CreateBookingDialog extends StatefulWidget {
  final MockDataService dataService;

  const CreateBookingDialog({super.key, required this.dataService});

  @override
  State<CreateBookingDialog> createState() => _CreateBookingDialogState();
}

class _CreateBookingDialogState extends State<CreateBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  MapElement? _selectedUmbrella;
  String? _selectedPackageId;
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final availableUmbrellas = _getAvailableUmbrellas();
    // Only the packages actually on sale for the selected umbrella's zone —
    // an admin shouldn't be able to sell a package the operator never priced
    // for that position. Before an umbrella is chosen, show every package.
    final packages = _selectedUmbrella == null
        ? widget.dataService.packages
        : widget.dataService.packagesForUmbrella(_selectedUmbrella!.id);
    if (_selectedPackageId != null && !packages.any((p) => p.id == _selectedPackageId)) {
      _selectedPackageId = null;
    }
    if (_selectedPackageId == null && packages.isNotEmpty) {
      _selectedPackageId = packages.first.id;
    }

    return AlertDialog(
      title: const Text('Nuova Prenotazione'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Cliente',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Inserisci il nome' : null,
              ),
              const SizedBox(height: 16),

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Dal',
                      date: _startDate,
                      onDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                          _selectedUmbrella = null; // Reset umbrella as availability changes
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Al',
                      date: _endDate,
                      firstDate: _startDate,
                      onDateSelected: (date) {
                        setState(() {
                          _endDate = date;
                          _selectedUmbrella = null; // Reset umbrella as availability changes
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Umbrella Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedUmbrella?.id,
                decoration: const InputDecoration(
                  labelText: 'Ombrellone',
                  prefixIcon: Icon(Icons.beach_access),
                  border: OutlineInputBorder(),
                ),
                items: availableUmbrellas.map((u) {
                  return DropdownMenuItem(
                    value: u.id,
                    child: Text(u.label ?? '${u.row}-${u.number}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUmbrella = widget.dataService.umbrellas.firstWhere((u) => u.id == value);
                  });
                },
                validator: (value) => value == null ? 'Seleziona un ombrellone' : null,
              ),
              if (availableUmbrellas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Nessun ombrellone disponibile per queste date',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Package Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedPackageId,
                decoration: const InputDecoration(
                  labelText: 'Pacchetto',
                  prefixIcon: Icon(Icons.local_offer),
                  border: OutlineInputBorder(),
                ),
                items: packages.map((p) {
                  final dayPrice = _selectedUmbrella == null
                      ? p.defaultBasePrice
                      : widget.dataService.priceForPackageOnUmbrella(p.id, _selectedUmbrella!.id, _startDate);
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (€${dayPrice.toStringAsFixed(2)}/giorno)'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPackageId = value),
              ),
              const SizedBox(height: 16),

              // Payment Status
              SwitchListTile(
                title: const Text('Già Pagato'),
                value: _isPaid,
                onChanged: (val) => setState(() => _isPaid = val),
                secondary: Icon(
                  _isPaid ? Icons.check_circle : Icons.circle_outlined,
                  color: _isPaid ? Colors.green : Colors.grey,
                ),
              ),

              const Divider(),
              
              // Total Price
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Totale: €${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Crea Prenotazione'),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    DateTime? firstDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(date)),
      ),
    );
  }

  List<MapElement> _getAvailableUmbrellas() {
    // Simple availability check: filter out umbrellas that have overlapping bookings
    final umbrellas = widget.dataService.umbrellas;
    final bookings = widget.dataService.bookings;

    return umbrellas.where((u) {
      // Check if this umbrella has any booking overlapping with selected dates
      bool isOccupied = bookings.any((b) {
        if (b.umbrellaId != u.id) return false;
        
        // Calculate booking end date (assuming duration logic matches)
        // For simplicity in this mock, let's assume bookings are stored with start date
        // and we need to check overlap.
        // Since Booking model only has 'date', let's assume it's the start date.
        // Real implementation should have startDate and endDate in Booking model.
        // For now, let's assume 1 day duration for existing bookings to simplify mock check
        // OR better, let's update Booking model to have endDate or duration.
        
        // Using the same simplified logic as BookingsManagementScreen for now:
        // Overlap check: (StartA <= EndB) and (EndA >= StartB)
        
        final bStart = b.startDate;
        final bEnd = b.endDate;
        
        return _startDate.isBefore(bEnd.add(const Duration(days: 1))) && _endDate.isAfter(bStart.subtract(const Duration(days: 1)));
      });
      
      return !isOccupied;
    }).toList();
  }

  double _calculateTotal() {
    if (_selectedPackageId == null || _selectedUmbrella == null) return 0.0;

    final days = _endDate.difference(_startDate).inDays + 1;
    double total = 0;
    for (int i = 0; i < days; i++) {
      final day = _startDate.add(Duration(days: i));
      total += widget.dataService
          .priceForPackageOnUmbrella(_selectedPackageId!, _selectedUmbrella!.id, day);
    }
    return total;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedUmbrella == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un ombrellone')),
        );
        return;
      }

      final newBooking = Booking(
        id: const Uuid().v4(),
        umbrellaId: _selectedUmbrella!.id,
        userId: 'manual_entry', // Placeholder for admin created
        startDate: _startDate,
        endDate: _endDate,
        status: BookingStatus.confirmed,
        customerName: _nameController.text,
        packageId: _selectedPackageId,
        totalPrice: _calculateTotal(),
        isPaid: _isPaid,
        channel: BookingChannel.onSite, // walk-in registered by the operator
      );

      // Add to service (re-validated server-side against overlaps)
      final error = widget.dataService.addBooking(newBooking);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        setState(() => _selectedUmbrella = null);
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prenotazione creata con successo!')),
      );
    }
  }
}
