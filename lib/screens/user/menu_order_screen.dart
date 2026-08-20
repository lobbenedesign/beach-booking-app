import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';
import '../../services/auth_service.dart';
import '../../models/menu_model.dart';

/// Customer-facing screen: order food & drinks directly from the umbrella.
/// Mirrors the "ordina dall'ombrellone" feature offered by Spiagge.it / Cocobuk.
class MenuOrderScreen extends StatefulWidget {
  const MenuOrderScreen({super.key});

  @override
  State<MenuOrderScreen> createState() => _MenuOrderScreenState();
}

class _MenuOrderScreenState extends State<MenuOrderScreen> {
  final Map<String, int> _cart = {}; // menuItemId -> qty
  String? _selectedUmbrellaId;
  final TextEditingController _manualLabel = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _manualLabel.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final auth = Provider.of<AuthService>(context, listen: false);
    final categories = data.menuCategories;
    final userId = auth.currentUser?.id ?? 'guest';

    // Active bookings of this user -> umbrella options
    final myBookings = data.getUserBookings(userId);
    final umbrellaOptions = {
      for (final b in myBookings) b.umbrellaId: data.umbrellaLabel(b.umbrellaId)
    };

    final total = _cart.entries.fold<double>(0, (sum, e) {
      final item = data.menuItems.where((i) => i.id == e.key).firstOrNull;
      return sum + (item?.price ?? 0) * e.value;
    });
    final itemCount = _cart.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bar & Ristorante'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildUmbrellaSelector(umbrellaOptions),
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text('Menu non ancora disponibile'))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      for (final cat in categories) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Row(
                            children: [
                              Icon(cat.icon ?? Icons.restaurant_menu,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(cat.name,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ...data.menuItems
                            .where((i) => i.categoryId == cat.id && i.isAvailable)
                            .map((item) => _buildItemTile(item)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomSheet: itemCount == 0
          ? null
          : _buildCartBar(context, data, itemCount, total, umbrellaOptions),
    );
  }

  Widget _buildUmbrellaSelector(Map<String, String> umbrellaOptions) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.beach_access, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: umbrellaOptions.isNotEmpty
                ? DropdownButtonFormField<String>(
                    initialValue: _selectedUmbrellaId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Consegna all\'ombrellone',
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: umbrellaOptions.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text('Ombrellone ${e.value}')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUmbrellaId = v),
                  )
                : TextField(
                    controller: _manualLabel,
                    decoration: const InputDecoration(
                      labelText: 'Numero ombrellone (es. A-5)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(MenuItem item) {
    final qty = _cart[item.id] ?? 0;
    final minQty = item.minOrderQuantity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _itemThumbnail(item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (item.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                if ((item.allergens ?? []).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Allergeni: ${item.allergens!.join(', ')}',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
                  ),
                if (item.hasMinimumOrder)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 13, color: Colors.deepOrange),
                        const SizedBox(width: 4),
                        Text(item.effectiveMinOrderNote!,
                            style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('€${item.price.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (qty > 0) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          if (qty <= minQty) {
                            _cart.remove(item.id);
                          } else {
                            _cart[item.id] = qty - 1;
                          }
                        }),
                      ),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.blue.shade700),
                      onPressed: () => setState(() => _cart[item.id] = qty == 0 ? minQty : qty + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 24),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(imageUrl.split(',').last),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade100,
          child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 24),
        ),
      ),
    );
  }

  Widget _buildCartBar(BuildContext context, MockDataService data, int itemCount,
      double total, Map<String, String> umbrellaOptions) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$itemCount articoli',
                    style: TextStyle(color: Colors.grey.shade600)),
                Text('€${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Invia ordine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () => _submitOrder(context, data, umbrellaOptions),
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder(BuildContext context, MockDataService data,
      Map<String, String> umbrellaOptions) {
    String? label;
    String? umbrellaId;
    if (umbrellaOptions.isNotEmpty) {
      umbrellaId = _selectedUmbrellaId;
      if (umbrellaId == null) {
        _snack(context, 'Seleziona il tuo ombrellone');
        return;
      }
      label = umbrellaOptions[umbrellaId];
    } else {
      label = _manualLabel.text.trim();
      if (label.isEmpty) {
        _snack(context, 'Inserisci il numero dell\'ombrellone');
        return;
      }
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final items = _cart.entries.map((e) {
      final mi = data.menuItems.firstWhere((i) => i.id == e.key);
      return OrderItem(
        menuItemId: mi.id,
        menuItemName: mi.name,
        unitPrice: mi.price,
        quantity: e.value,
      );
    }).toList();

    data.placeOrder(
      umbrellaId: umbrellaId,
      umbrellaLabel: label,
      customerName: auth.currentUser?.name,
      items: items,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    setState(() => _cart.clear());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Ordine inviato!'),
        content: Text(
            'Il tuo ordine è stato inviato al bar e verrà servito all\'ombrellone $label.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
