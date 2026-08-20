import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/mock_data_service.dart';
import '../../models/menu_model.dart';
import '../../widgets/admin/admin_scaffold.dart';

/// Bar/Restaurant management for the operator:
/// - "Ordini Live": kitchen/bar board with order status flow
/// - "Menu": CRUD of categories & items
class OrdersManagementScreen extends StatelessWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: AdminScaffold(
        title: 'Bar & Ordini',
        selectedIndex: 5,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.blue,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(icon: Icon(Icons.receipt_long), text: 'Ordini Live'),
                Tab(icon: Icon(Icons.menu_book), text: 'Gestione Menu'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LiveOrdersTab(),
                  _MenuManagementTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveOrdersTab extends StatelessWidget {
  const _LiveOrdersTab();

  static const _columns = [
    (OrderStatus.pending, 'In attesa', Colors.orange),
    (OrderStatus.preparing, 'In preparazione', Colors.blue),
    (OrderStatus.ready, 'Pronto', Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final active = data.activeOrders;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _summaryChip('Ordini attivi', '${active.length}', Colors.orange),
              const SizedBox(width: 12),
              _summaryChip('Incasso oggi',
                  '€${data.todayOrdersRevenue.toStringAsFixed(2)}', Colors.green),
            ],
          ),
        ),
        Expanded(
          child: active.isEmpty
              ? const Center(child: Text('Nessun ordine attivo'))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _columns.map((col) {
                    final orders =
                        active.where((o) => o.status == col.$1).toList();
                    return Expanded(
                      child: _buildColumn(context, data, col.$2, col.$3, orders),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$value  ',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        Text(label, style: TextStyle(color: color)),
      ]),
    );
  }

  Widget _buildColumn(BuildContext context, MockDataService data, String title,
      Color color, List<Order> orders) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text('$title (${orders.length})',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: orders.map((o) => _orderCard(context, data, o)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(BuildContext context, MockDataService data, Order o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.beach_access, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text(o.umbrellaLabel ?? 'Bancone',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(DateFormat('HH:mm').format(o.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            if (o.customerName != null)
              Text(o.customerName!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const Divider(),
            ...o.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${i.quantity}× ${i.menuItemName}'),
                )),
            if (o.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Note: ${o.notes}',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 12)),
              ),
            const SizedBox(height: 6),
            Text('€${o.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (o.status != OrderStatus.pending)
                  TextButton(
                    onPressed: () => data.updateOrderStatus(o.id, _prev(o.status)),
                    child: const Text('◀'),
                  ),
                const Spacer(),
                if (o.status == OrderStatus.ready)
                  ElevatedButton(
                    onPressed: () =>
                        data.updateOrderStatus(o.id, OrderStatus.served),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text('Servito'),
                  )
                else
                  ElevatedButton(
                    onPressed: () =>
                        data.updateOrderStatus(o.id, _next(o.status)),
                    child: Text(_nextLabel(o.status)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  OrderStatus _next(OrderStatus s) => switch (s) {
        OrderStatus.pending => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        _ => OrderStatus.served,
      };
  OrderStatus _prev(OrderStatus s) => switch (s) {
        OrderStatus.ready => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.pending,
        _ => OrderStatus.pending,
      };
  String _nextLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'Prepara',
        OrderStatus.preparing => 'Pronto',
        _ => 'Servito',
      };
}

class _MenuManagementTab extends StatelessWidget {
  const _MenuManagementTab();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(context, data),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo articolo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final cat in data.menuCategories) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(cat.icon ?? Icons.restaurant_menu, color: Colors.blue),
                const SizedBox(width: 8),
                Text(cat.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
            ...data.menuItems.where((i) => i.categoryId == cat.id).map((item) {
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('€${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: item.isAvailable,
                        onChanged: (v) => data
                            .updateMenuItem(item.copyWith(isAvailable: v)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editItem(context, data, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => data.deleteMenuItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _editItem(BuildContext context, MockDataService data, [MenuItem? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.price.toStringAsFixed(2) ?? '');
    String categoryId = existing?.categoryId ??
        (data.menuCategories.isNotEmpty ? data.menuCategories.first.id : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nuovo articolo' : 'Modifica articolo'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrizione'),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prezzo (€)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: categoryId.isEmpty ? null : categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: data.menuCategories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => categoryId = v ?? categoryId),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
              if (nameCtrl.text.trim().isEmpty || categoryId.isEmpty) return;
              if (existing == null) {
                data.addMenuItem(MenuItem(
                  id: const Uuid().v4(),
                  categoryId: categoryId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  price: price,
                ));
              } else {
                data.updateMenuItem(existing.copyWith(
                  categoryId: categoryId,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: price,
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
