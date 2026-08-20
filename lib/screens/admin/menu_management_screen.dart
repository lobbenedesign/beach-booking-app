import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/menu_model.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/admin/admin_scaffold.dart';

/// Operator menu editor: categories (Antipasti/Pizze/Primi/Secondi/Dessert/
/// Bevande), items with price, description, photo, allergens and an
/// optional minimum-order quantity (e.g. a risotto made for 2+ people).
/// Feeds both the customer ordering screen and the kitchen/bar workflow.
class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final categories = [...data.menuCategories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
    final items = data.menuItems
        .where((i) => i.categoryId == _selectedCategoryId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AdminScaffold(
      title: 'Gestione Menu',
      selectedIndex: 20,
      actions: [
        IconButton(
          icon: const Icon(Icons.create_new_folder_outlined, color: Colors.white),
          tooltip: 'Nuova categoria',
          onPressed: () => _showCategoryDialog(context, data),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Nuovo piatto',
          onPressed: _selectedCategoryId == null
              ? null
              : () => _showItemDialog(context, data, categoryId: _selectedCategoryId!),
        ),
      ],
      child: Column(
        children: [
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: categories.map((c) {
                  final selected = c.id == _selectedCategoryId;
                  final count = data.menuItems.where((i) => i.categoryId == c.id).length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InputChip(
                      label: Text('${c.name} ($count)'),
                      avatar: Icon(c.icon ?? Icons.restaurant_menu, size: 18),
                      selected: selected,
                      onPressed: () => setState(() => _selectedCategoryId = c.id),
                      onDeleted: () => _confirmDeleteCategory(context, data, c),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text('Crea una categoria per iniziare', style: TextStyle(color: Colors.grey)))
                : items.isEmpty
                    ? const Center(child: Text('Nessun piatto in questa categoria', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _buildItemCard(context, data, items[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, MockDataService data, MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: item.isAvailable ? Colors.black87 : Colors.grey)),
                      ),
                      Text('€${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item.description!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ),
                  if ((item.allergens ?? []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: item.allergens!
                            .map((a) => Chip(
                                  label: Text(a, style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.orange.shade50,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ),
                  if (item.hasMinimumOrder)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text(item.effectiveMinOrderNote!,
                              style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (!item.isAvailable)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Non disponibile', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: item.isAvailable,
                  onChanged: (v) => data.updateMenuItem(item.copyWith(isAvailable: v)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showItemDialog(context, data, categoryId: item.categoryId, existing: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeleteItem(context, data, item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.restaurant, color: Colors.grey.shade400),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(imageUrl.split(',').last),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade100,
          child: Icon(Icons.broken_image, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, MockDataService data, MenuCategory c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la categoria?'),
        content: Text('"${c.name}" e tutti i piatti al suo interno verranno eliminati.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              data.deleteMenuCategory(c.id);
              Navigator.pop(context);
              setState(() {
                if (_selectedCategoryId == c.id) _selectedCategoryId = null;
              });
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(BuildContext context, MockDataService data, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il piatto?'),
        content: Text('Eliminare "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              data.deleteMenuItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, MockDataService data) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Categoria'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome (es. Antipasti)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final cat = MenuCategory(
                id: const Uuid().v4(),
                name: name,
                sortOrder: data.menuCategories.length,
                icon: Icons.restaurant_menu,
              );
              data.addMenuCategory(cat);
              Navigator.pop(context);
              setState(() => _selectedCategoryId = cat.id);
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, MockDataService data,
      {required String categoryId, MenuItem? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(text: existing?.price.toStringAsFixed(2) ?? '');
    final minNoteController = TextEditingController(text: existing?.minOrderNote ?? '');
    final selectedAllergens = <String>{...?existing?.allergens};
    String? imageUrl = existing?.imageUrl;
    int minQty = existing?.minOrderQuantity ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nuovo Piatto' : 'Modifica Piatto'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['png', 'jpg', 'jpeg'],
                          withData: true,
                        );
                        final bytes = result?.files.single.bytes;
                        final name = result?.files.single.name ?? '';
                        if (bytes == null) return;
                        final ext = name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
                        setLocal(() => imageUrl = 'data:image/$ext;base64,${base64Encode(bytes)}');
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: MemoryImage(base64Decode(imageUrl!.split(',').last)),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageUrl == null
                            ? Icon(Icons.add_a_photo, color: Colors.grey.shade400)
                            : Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome piatto')),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrizione'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Prezzo (€)', prefixIcon: Icon(Icons.euro)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  const Text('Allergeni', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kStandardAllergens.map((a) {
                      final on = selectedAllergens.contains(a);
                      return FilterChip(
                        label: Text(a, style: const TextStyle(fontSize: 12)),
                        selected: on,
                        onSelected: (v) => setLocal(() {
                          if (v) {
                            selectedAllergens.add(a);
                          } else {
                            selectedAllergens.remove(a);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Ordine minimo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: minQty > 1 ? () => setLocal(() => minQty--) : null,
                      ),
                      Text('$minQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setLocal(() => minQty++),
                      ),
                    ],
                  ),
                  if (minQty > 1)
                    TextField(
                      controller: minNoteController,
                      decoration: InputDecoration(
                          labelText: 'Nota ordine minimo (opzionale)',
                          hintText: 'Minimo $minQty persone'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                if (name.isEmpty || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inserisci nome e prezzo validi')));
                  return;
                }
                final item = MenuItem(
                  id: existing?.id ?? const Uuid().v4(),
                  categoryId: categoryId,
                  name: name,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  price: price,
                  isAvailable: existing?.isAvailable ?? true,
                  imageUrl: imageUrl,
                  allergens: selectedAllergens.isEmpty ? null : selectedAllergens.toList(),
                  sortOrder: existing?.sortOrder ?? data.menuItems.where((i) => i.categoryId == categoryId).length,
                  minOrderQuantity: minQty,
                  minOrderNote: minNoteController.text.trim().isEmpty ? null : minNoteController.text.trim(),
                );
                if (existing == null) {
                  data.addMenuItem(item);
                } else {
                  data.updateMenuItem(item);
                }
                Navigator.pop(context);
              },
              child: Text(existing == null ? 'Crea' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
