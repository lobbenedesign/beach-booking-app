import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/extra_service_model.dart';
import '../../services/auth_service.dart';
import '../../services/mock_data_service.dart';

/// Customer-facing catalog for on-demand extras (bar orders, timed activity
/// rentals, at-umbrella services) — an order placed here reaches the
/// operator's "Ordini Extra" admin screen immediately, since both share the
/// same MockDataService instance.
class ExtraServicesScreen extends StatefulWidget {
  const ExtraServicesScreen({super.key});

  @override
  State<ExtraServicesScreen> createState() => _ExtraServicesScreenState();
}

class _ExtraServicesScreenState extends State<ExtraServicesScreen> {
  String? _selectedUmbrellaId;
  bool _umbrellaInitialized = false;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id;
    final items = data.availableExtraServiceItems;

    if (!_umbrellaInitialized && userId != null) {
      final today = DateTime.now();
      final activeBooking = data
          .getUserBookings(userId)
          .where((b) => !today.isBefore(b.startDate) && !today.isAfter(b.endDate))
          .firstOrNull;
      _selectedUmbrellaId = activeBooking?.umbrellaId;
      _umbrellaInitialized = true;
    }

    final byCategory = <ExtraServiceCategory, List<ExtraServiceItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Servizi Extra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedUmbrellaId != null)
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.beach_access, color: Colors.blue),
                title: Text('Consegna all\'ombrellone ${data.umbrellaLabel(_selectedUmbrellaId!)}'),
                subtitle: const Text('Rilevato dalla tua prenotazione di oggi'),
              ),
            ),
          for (final category in ExtraServiceCategory.values)
            if (byCategory[category]?.isNotEmpty ?? false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(category.label,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              for (final item in byCategory[category]!)
                _ExtraServiceCard(
                  item: item,
                  price: data.priceForExtraService(item.id, DateTime.now()),
                  onOrder: (quantity) => _placeOrder(context, data, userId, item, quantity),
                ),
            ],
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context, MockDataService data, String? userId, ExtraServiceItem item, int quantity) {
    if (userId == null) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    final order = data.placeExtraServiceOrder(
      userId: userId,
      customerName: auth.currentUser?.name ?? 'Cliente',
      itemId: item.id,
      quantity: quantity,
      umbrellaId: _selectedUmbrellaId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ordine inviato: ${item.name} x$quantity · €${order.totalPrice.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _ExtraServiceCard extends StatefulWidget {
  final ExtraServiceItem item;
  final double price;
  final ValueChanged<int> onOrder;

  const _ExtraServiceCard({required this.item, required this.price, required this.onOrder});

  @override
  State<_ExtraServiceCard> createState() => _ExtraServiceCardState();
}

class _ExtraServiceCardState extends State<_ExtraServiceCard> {
  int _quantity = 1;

  IconData get _categoryIcon {
    switch (widget.item.category) {
      case ExtraServiceCategory.bar:
        return Icons.local_bar;
      case ExtraServiceCategory.rental:
        return Icons.rowing;
      case ExtraServiceCategory.court:
        return Icons.sports_tennis;
      case ExtraServiceCategory.umbrellaService:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              child: Icon(_categoryIcon, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (item.durationMinutes != null)
                        Chip(
                          label: Text('${item.durationMinutes} min'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (item.capacity != null)
                        Chip(
                          label: Text(item.capacity == 1 ? 'Singola' : '${item.capacity} persone'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('€${widget.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => widget.onOrder(_quantity),
                        child: const Text('Ordina'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
