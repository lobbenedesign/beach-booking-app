import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/extra_service_model.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../utils/neumorphic_theme.dart';

/// Live order queue for on-demand extras (bar orders, timed rentals,
/// at-umbrella services) plus catalog and seasonal-pricing management for
/// the same items — three tabs so the whole extras marketplace lives in one
/// place instead of spreading across the sidebar.
class ExtraOrdersScreen extends StatefulWidget {
  const ExtraOrdersScreen({super.key});

  @override
  State<ExtraOrdersScreen> createState() => _ExtraOrdersScreenState();
}

class _ExtraOrdersScreenState extends State<ExtraOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    return AdminScaffold(
      title: 'Ordini Extra',
      selectedIndex: 40,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: NeumorphicTheme.background,
              boxShadow: [
                BoxShadow(color: NeumorphicTheme.darkShadow.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 8),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: NeumorphicTheme.accent,
              unselectedLabelColor: NeumorphicTheme.textSecondary,
              indicatorColor: NeumorphicTheme.accent,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Ordini${data.pendingExtraOrdersCount > 0 ? ' (${data.pendingExtraOrdersCount})' : ''}'),
                const Tab(text: 'Catalogo'),
                const Tab(text: 'Prezzi Stagionali'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: NeumorphicTheme.background,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _OrdersTab(),
                  _CatalogTab(),
                  _SeasonalPricesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ORDERS TAB ---
class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final orders = data.extraServiceOrders;

    if (orders.isEmpty) {
      return const Center(child: Text('Nessun ordine ricevuto', style: TextStyle(color: NeumorphicTheme.textSecondary)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final item = data.extraServiceItems.where((i) => i.id == order.itemId).firstOrNull;
        return _OrderCard(order: order, item: item, dataService: data);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ExtraServiceOrder order;
  final ExtraServiceItem? item;
  final MockDataService dataService;

  const _OrderCard({required this.order, required this.item, required this.dataService});

  Color get _statusColor {
    switch (order.status) {
      case ExtraOrderStatus.pending:
        return Colors.orange;
      case ExtraOrderStatus.confirmed:
        return Colors.blue;
      case ExtraOrderStatus.delivered:
        return Colors.green;
      case ExtraOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item?.name ?? order.itemId} x${order.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${order.customerName}'
                  '${order.umbrellaId != null ? ' · Ombrellone ${dataService.umbrellaLabel(order.umbrellaId!)}' : ''}'
                  ' · ${DateFormat('HH:mm').format(order.requestedAt)}',
                  style: const TextStyle(color: NeumorphicTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text('€${order.totalPrice.toStringAsFixed(2)} · ${order.status.label}',
                    style: TextStyle(color: _statusColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (order.status == ExtraOrderStatus.pending) ...[
            TextButton(
              onPressed: () => dataService.updateExtraOrderStatus(order.id, ExtraOrderStatus.cancelled),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => dataService.updateExtraOrderStatus(order.id, ExtraOrderStatus.confirmed),
              child: const Text('Conferma'),
            ),
          ] else if (order.status == ExtraOrderStatus.confirmed)
            ElevatedButton(
              onPressed: () => dataService.updateExtraOrderStatus(order.id, ExtraOrderStatus.delivered),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Consegnato'),
            ),
        ],
      ),
    );
  }
}

// --- CATALOG TAB ---
class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final items = data.extraServiceItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeumorphicTheme.accent,
        onPressed: () => _showItemDialog(context, data),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return NeumorphicCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: NeumorphicTheme.pressed(borderRadius: 24),
                child: item.iconImage != null
                    ? Image.memory(base64Decode(item.iconImage!.split(',').last), fit: BoxFit.cover)
                    : const Icon(Icons.room_service, color: NeumorphicTheme.accent),
              ),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item.category.label} · €${item.defaultPrice.toStringAsFixed(2)}'
                  '${item.durationMinutes != null ? ' · ${item.durationMinutes} min' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: item.available,
                    onChanged: (v) {
                      item.available = v;
                      data.updateExtraServiceItem(item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: NeumorphicTheme.accent),
                    onPressed: () => _showItemDialog(context, data, item: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => data.deleteExtraServiceItem(item.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showItemDialog(BuildContext context, MockDataService data, {ExtraServiceItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: (item?.defaultPrice ?? 0.0).toString());
    final durationController = TextEditingController(text: item?.durationMinutes?.toString() ?? '');
    final capacityController = TextEditingController(text: item?.capacity?.toString() ?? '');
    ExtraServiceCategory category = item?.category ?? ExtraServiceCategory.bar;
    String? iconImage = item?.iconImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(item == null ? 'Nuovo Servizio Extra' : 'Modifica Servizio Extra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: NeumorphicTheme.pressed(borderRadius: 12),
                      child: iconImage != null
                          ? Image.memory(base64Decode(iconImage!.split(',').last), fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: NeumorphicTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final result =
                            await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg'], withData: true);
                        final bytes = result?.files.single.bytes;
                        final fname = result?.files.single.name ?? '';
                        if (bytes == null) return;
                        final ext = fname.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
                        setLocal(() => iconImage = 'data:image/$ext;base64,${base64Encode(bytes)}');
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Descrizione', border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExtraServiceCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                  items: ExtraServiceCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) => setLocal(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Prezzo Base (€)', border: OutlineInputBorder(), prefixText: '€ '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(labelText: 'Durata (min, opz.)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: capacityController,
                        decoration: const InputDecoration(labelText: 'Capienza (opz.)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final newItem = ExtraServiceItem(
                  id: item?.id ?? const Uuid().v4(),
                  name: name,
                  description: descController.text.trim(),
                  category: category,
                  durationMinutes: int.tryParse(durationController.text),
                  capacity: int.tryParse(capacityController.text),
                  defaultPrice: double.tryParse(priceController.text) ?? 0.0,
                  iconImage: iconImage,
                  available: item?.available ?? true,
                );
                if (item == null) {
                  data.addExtraServiceItem(newItem);
                } else {
                  data.updateExtraServiceItem(newItem);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SEASONAL PRICES TAB ---
class _SeasonalPricesTab extends StatefulWidget {
  const _SeasonalPricesTab();

  @override
  State<_SeasonalPricesTab> createState() => _SeasonalPricesTabState();
}

class _SeasonalPricesTabState extends State<_SeasonalPricesTab> {
  String? _selectedItemId;
  String? _selectedSeasonId;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final items = data.extraServiceItems;
    final seasons = data.seasons;

    if (_selectedItemId == null && items.isNotEmpty) _selectedItemId = items.first.id;
    if (_selectedSeasonId == null && seasons.isNotEmpty) _selectedSeasonId = seasons.first.id;

    final entry = data.extraPriceList
        .where((p) => p.itemId == _selectedItemId && p.seasonId == _selectedSeasonId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        NeumorphicCard(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedItemId,
                  decoration: const InputDecoration(labelText: 'Servizio Extra', border: OutlineInputBorder()),
                  items: items.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedItemId = v),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSeasonId,
                  decoration: const InputDecoration(labelText: 'Stagione', border: OutlineInputBorder()),
                  items: seasons.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedSeasonId = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedItemId != null && _selectedSeasonId != null)
          NeumorphicCard(
            padding: const EdgeInsets.all(20),
            child: _PriceEntryForm(
              key: ValueKey('${_selectedItemId}_$_selectedSeasonId'),
              itemId: _selectedItemId!,
              seasonId: _selectedSeasonId!,
              entry: entry,
              dataService: data,
            ),
          ),
      ],
    );
  }
}

class _PriceEntryForm extends StatefulWidget {
  final String itemId;
  final String seasonId;
  final ExtraPriceListEntry? entry;
  final MockDataService dataService;

  const _PriceEntryForm({super.key, required this.itemId, required this.seasonId, required this.entry, required this.dataService});

  @override
  State<_PriceEntryForm> createState() => _PriceEntryFormState();
}

class _PriceEntryFormState extends State<_PriceEntryForm> {
  late final TextEditingController _weekdayController;
  late final TextEditingController _fridayController;
  late final TextEditingController _saturdayController;
  late final TextEditingController _sundayController;

  @override
  void initState() {
    super.initState();
    _weekdayController = TextEditingController(text: widget.entry?.weekdayPrice.toString() ?? '');
    _fridayController = TextEditingController(text: widget.entry?.fridayPrice?.toString() ?? '');
    _saturdayController = TextEditingController(text: widget.entry?.saturdayPrice?.toString() ?? '');
    _sundayController = TextEditingController(text: widget.entry?.sundayPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _weekdayController.dispose();
    _fridayController.dispose();
    _saturdayController.dispose();
    _sundayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prezzo per il periodo selezionato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _priceField('Feriale (lun-gio)', _weekdayController, required: true),
            _priceField('Venerdì (opz.)', _fridayController),
            _priceField('Sabato (opz.)', _saturdayController),
            _priceField('Domenica (opz.)', _sundayController),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton(
              onPressed: _save,
              child: const Text('Salva Prezzo'),
            ),
            if (widget.entry != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  widget.dataService.deleteExtraPriceListEntry(widget.entry!.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Rimuovi override (torna al prezzo base)'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _priceField(String label, TextEditingController controller, {bool required = false}) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixText: '€ '),
        keyboardType: TextInputType.number,
      ),
    );
  }

  void _save() {
    final weekday = double.tryParse(_weekdayController.text);
    if (weekday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il prezzo feriale è obbligatorio')),
      );
      return;
    }
    final newEntry = ExtraPriceListEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      itemId: widget.itemId,
      seasonId: widget.seasonId,
      weekdayPrice: weekday,
      fridayPrice: double.tryParse(_fridayController.text),
      saturdayPrice: double.tryParse(_saturdayController.text),
      sundayPrice: double.tryParse(_sundayController.text),
    );
    if (widget.entry == null) {
      widget.dataService.addExtraPriceListEntry(newEntry);
    } else {
      widget.dataService.updateExtraPriceListEntry(newEntry);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prezzo salvato'), backgroundColor: Colors.green),
    );
  }
}
