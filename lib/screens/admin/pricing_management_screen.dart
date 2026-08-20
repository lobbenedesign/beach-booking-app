import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/beach_model.dart';
import '../../services/mock_data_service.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/admin/admin_scaffold.dart';
import '../../utils/neumorphic_theme.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  State<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> with SingleTickerProviderStateMixin {
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
    return AdminScaffold(
      title: 'Listino e Prezzi',
      selectedIndex: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: NeumorphicTheme.background,
              boxShadow: [
                BoxShadow(
                  color: NeumorphicTheme.darkShadow.withOpacity(0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: NeumorphicTheme.accent,
              unselectedLabelColor: NeumorphicTheme.textSecondary,
              indicatorColor: NeumorphicTheme.accent,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Pacchetti'),
                Tab(text: 'Stagionalità'),
                Tab(text: 'Listino Prezzi'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: NeumorphicTheme.background,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PackagesTab(),
                  _SeasonsTab(),
                  _PriceMatrixTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom dropdown that works inside TabBarView (no LookupBoundary issues) ───
class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: NeumorphicTheme.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeumorphicTheme.radiusSmall),
            borderSide: BorderSide(color: NeumorphicTheme.darkShadow.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeumorphicTheme.radiusSmall),
            borderSide: BorderSide(color: NeumorphicTheme.darkShadow.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeumorphicTheme.radiusSmall),
            borderSide: const BorderSide(color: NeumorphicTheme.accent, width: 2),
          ),
          filled: true,
          fillColor: NeumorphicTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// --- PACKAGES TAB ---
class _PackagesTab extends StatelessWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final packages = dataService.packages;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeumorphicTheme.accent,
        onPressed: () => _showPackageDialog(context, dataService),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return NeumorphicCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: NeumorphicTheme.pressed(borderRadius: 24),
                child: pkg.iconImage != null
                    ? Image.memory(
                        base64Decode(pkg.iconImage!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          pkg.name[0],
                          style: const TextStyle(
                            color: NeumorphicTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
              ),
              title: Text(
                pkg.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  pkg.items.join(', '),
                  style: const TextStyle(color: NeumorphicTheme.textSecondary),
                ),
              ),
              trailing: NeumorphicButton(
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                onPressed: () => _showPackageDialog(context, dataService, package: pkg),
                child: const Icon(Icons.edit, color: NeumorphicTheme.accent, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPackageDialog(BuildContext context, MockDataService dataService, {ServicePackage? package}) {
    final nameController = TextEditingController(text: package?.name ?? '');
    final descController = TextEditingController(text: package?.description ?? '');
    final priceController = TextEditingController(text: (package?.defaultBasePrice ?? 0.0).toString());
    final itemsController = TextEditingController(text: package?.items.join(', ') ?? '');
    String? iconImage = package?.iconImage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(package == null ? 'Nuovo Pacchetto' : 'Modifica Pacchetto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: NeumorphicTheme.pressed(borderRadius: 12),
                      child: iconImage != null
                          ? Image.memory(base64Decode(iconImage!.split(',').last), fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: NeumorphicTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['png', 'jpg', 'jpeg'],
                                withData: true,
                              );
                              final bytes = result?.files.single.bytes;
                              final fname = result?.files.single.name ?? '';
                              if (bytes == null) return;
                              final ext = fname.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
                              setLocal(() => iconImage = 'data:image/$ext;base64,${base64Encode(bytes)}');
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Carica foto'),
                          ),
                          if (iconImage != null)
                            TextButton.icon(
                              onPressed: () => setLocal(() => iconImage = null),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Rimuovi'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome Pacchetto', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrizione', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemsController,
                  decoration: const InputDecoration(
                    labelText: 'Elementi (separati da virgola)',
                    border: OutlineInputBorder(),
                    hintText: 'Es: 1 Ombrellone, 2 Lettini',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Prezzo Base (€)', border: OutlineInputBorder(), prefixText: '€ '),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Il nome è obbligatorio')),
                  );
                  return;
                }
                final items = itemsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final price = double.tryParse(priceController.text) ?? 0.0;
                if (package == null) {
                  dataService.addPackage(ServicePackage(
                    id: const Uuid().v4(),
                    name: name,
                    items: items,
                    description: descController.text.trim(),
                    defaultBasePrice: price,
                    iconImage: iconImage,
                  ));
                } else {
                  dataService.updatePackage(ServicePackage(
                    id: package.id,
                    name: name,
                    items: items,
                    description: descController.text.trim(),
                    defaultBasePrice: price,
                    iconImage: iconImage,
                  ));
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pacchetto "$name" ${package == null ? "creato" : "aggiornato"}!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SEASONS TAB ---
class _SeasonsTab extends StatelessWidget {
  const _SeasonsTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final seasons = dataService.seasons;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeumorphicTheme.accent,
        onPressed: () => _showSeasonDialog(context, dataService),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final season = seasons[index];
          return NeumorphicCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: NeumorphicTheme.pressed(borderRadius: 24),
                child: const Icon(Icons.calendar_month, color: NeumorphicTheme.accent),
              ),
              title: Text(
                season.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NeumorphicTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${_formatDate(season.startDate)} - ${_formatDate(season.endDate)}',
                  style: const TextStyle(color: NeumorphicTheme.textSecondary),
                ),
              ),
              trailing: NeumorphicButton(
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                onPressed: () => _showSeasonDialog(context, dataService, season: season),
                child: const Icon(Icons.edit, color: NeumorphicTheme.accent, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showSeasonDialog(BuildContext context, MockDataService dataService, {Season? season}) {
    final nameController = TextEditingController(text: season?.name ?? '');
    DateTime startDate = season?.startDate ?? DateTime.now();
    DateTime endDate = season?.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(season == null ? 'Nuova Stagione' : 'Modifica Stagione'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome Stagione', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data Inizio'),
                  subtitle: Text(_formatDate(startDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && dialogContext.mounted) setState(() => startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data Fine'),
                  subtitle: Text(_formatDate(endDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && dialogContext.mounted) setState(() => endDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Il nome è obbligatorio')),
                  );
                  return;
                }
                if (endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('La data fine deve essere dopo la data inizio')),
                  );
                  return;
                }

                // Seasons are meant to be consecutive, non-overlapping
                // sub-periods of the year (e.g. "Bassa Stagione" then "Alta
                // Stagione" back to back) — each has its own weekday/weekend
                // price list, and activeSeasonOn() only ever returns one
                // season per date. A genuine overlap is therefore a mistake,
                // not a legitimate configuration, so it's blocked outright
                // (MockDataService re-validates this too).
                final String? error = season == null
                    ? dataService.addSeason(Season(id: const Uuid().v4(), name: name, startDate: startDate, endDate: endDate))
                    : dataService.updateSeason(Season(id: season.id, name: name, startDate: startDate, endDate: endDate));

                if (error != null) {
                  showDialog(
                    context: dialogContext,
                    builder: (warnContext) => AlertDialog(
                      title: const Text('Periodo sovrapposto'),
                      content: Text(
                          '$error.\n\nLe stagioni non possono sovrapporsi (ogni data deve appartenere a una sola stagione). Modifica le date in modo che non si intersechino con quelle esistenti.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(warnContext), child: const Text('Ho capito')),
                      ],
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stagione "$name" ${season == null ? "creata" : "aggiornata"}!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PRICE MATRIX TAB ---
class _PriceMatrixTab extends StatefulWidget {
  const _PriceMatrixTab();

  @override
  State<_PriceMatrixTab> createState() => _PriceMatrixTabState();
}

class _PriceMatrixTabState extends State<_PriceMatrixTab> {
  String? _selectedSeasonId;
  String? _selectedPackageId;

  // Fixed column widths
  static const double _colZona   = 150.0;
  static const double _colPrice  = 90.0;
  static const double _colAction = 48.0;
  static const double _tableWidth = _colZona + _colPrice * 4 + _colAction + 32;

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final seasons  = dataService.seasons;
    final packages = dataService.packages;
    final zones    = dataService.zones;
    final priceList = dataService.priceList;

    if (_selectedSeasonId == null  && seasons.isNotEmpty)  _selectedSeasonId  = seasons.first.id;
    if (_selectedPackageId == null && packages.isNotEmpty) _selectedPackageId = packages.first.id;

    final relevantPrices = priceList
        .where((pl) => pl.seasonId == _selectedSeasonId && pl.packageId == _selectedPackageId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Filters ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: NeumorphicCard(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _LabeledDropdown<String>(
                    label: 'Pacchetto',
                    value: _selectedPackageId,
                    items: packages
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPackageId = val),
                  ),
                  _LabeledDropdown<String>(
                    label: 'Stagione',
                    value: _selectedSeasonId,
                    items: seasons
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSeasonId = val),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Table: sticky header + scrollable rows ────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: NeumorphicCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _tableWidth,
                    child: Column(
                      children: [
                        // Header row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: NeumorphicTheme.darkShadow.withOpacity(0.2))),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: _colZona,
                                child: Text(
                                  'Zona / Fila',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: NeumorphicTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _headerCell('Lun-Gio'),
                              _headerCell('Ven'),
                              _headerCell('Sab'),
                              _headerCell('Dom'),
                              const SizedBox(width: _colAction),
                            ],
                          ),
                        ),

                        // Body rows (vertically scrollable)
                        Expanded(
                          child: ListView.builder(
                            itemCount: zones.length,
                            itemBuilder: (context, index) {
                              final zone  = zones[index];
                              final entry = relevantPrices
                                  .where((pl) => pl.zoneId == zone.id)
                                  .firstOrNull;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: NeumorphicTheme.darkShadow.withOpacity(0.1))),
                                ),
                                child: Row(
                                  children: [
                                    // Zone colour dot + name
                                    SizedBox(
                                      width: _colZona,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            margin: const EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              color: zone.color,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: zone.color.withOpacity(0.4),
                                                  blurRadius: 4,
                                                  offset: const Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              zone.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: NeumorphicTheme.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _priceCell(entry != null ? '€${entry.weekdayPrice}' : '-'),
                                    _priceCell(entry != null ? '€${entry.fridayPrice   ?? entry.weekdayPrice}' : '-'),
                                    _priceCell(entry != null ? '€${entry.saturdayPrice ?? entry.weekdayPrice}' : '-'),
                                    _priceCell(entry != null ? '€${entry.sundayPrice   ?? entry.weekdayPrice}' : '-'),
                                    SizedBox(
                                      width: _colAction,
                                      child: NeumorphicButton(
                                        padding: const EdgeInsets.all(8),
                                        borderRadius: 8,
                                        onPressed: () => _showPriceEntryDialog(context, dataService, zone, entry),
                                        child: const Icon(Icons.edit, color: NeumorphicTheme.accent, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) => SizedBox(
        width: _colPrice,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: NeumorphicTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _priceCell(String value) => SizedBox(
        width: _colPrice,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: NeumorphicTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );

  void _showPriceEntryDialog(BuildContext context, MockDataService dataService, BeachZone zone, PriceListEntry? entry) {
    final weekdayController = TextEditingController(text: (entry?.weekdayPrice ?? 0.0).toString());
    final fridayController = TextEditingController(text: entry?.fridayPrice?.toString() ?? '');
    final saturdayController = TextEditingController(text: entry?.saturdayPrice?.toString() ?? '');
    final sundayController = TextEditingController(text: entry?.sundayPrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Prezzo — ${zone.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weekdayController,
                decoration: const InputDecoration(labelText: 'Lun-Gio (€)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fridayController,
                decoration: const InputDecoration(labelText: 'Venerdì (€, vuoto = usa Lun-Gio)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: saturdayController,
                decoration: const InputDecoration(labelText: 'Sabato (€, vuoto = usa Lun-Gio)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sundayController,
                decoration: const InputDecoration(labelText: 'Domenica (€, vuoto = usa Lun-Gio)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedPackageId == null || _selectedSeasonId == null) {
                Navigator.pop(dialogContext);
                return;
              }
              final newEntry = PriceListEntry(
                id: entry?.id ?? const Uuid().v4(),
                packageId: _selectedPackageId!,
                zoneId: zone.id,
                seasonId: _selectedSeasonId!,
                weekdayPrice: double.tryParse(weekdayController.text) ?? 0.0,
                fridayPrice: double.tryParse(fridayController.text),
                saturdayPrice: double.tryParse(saturdayController.text),
                sundayPrice: double.tryParse(sundayController.text),
              );
              dataService.updatePriceListEntry(newEntry);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prezzo aggiornato!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
