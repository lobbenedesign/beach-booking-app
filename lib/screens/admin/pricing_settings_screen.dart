import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import '../../widgets/admin/zone_editor_dialog.dart';
import '../../widgets/admin/admin_scaffold.dart';

class PricingSettingsScreen extends StatelessWidget {
  const PricingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Listini e Pacchetti',
      selectedIndex: 3,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Zone Spiaggia'),
                  Tab(text: 'Pacchetti'),
                  Tab(text: 'Regole Calendario'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _ZonesTab(),
                  _PackagesTab(),
                  _RulesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesTab extends StatelessWidget {
  const _ZonesTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final zones = dataService.zones;
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showZoneEditor(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          final umbrellaCount = dataService.umbrellas.where((u) => u.zoneId == zone.id).length;
          
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: zone.color),
              title: Text(zone.name),
              subtitle: Text(
                zone.pricingType == PricingType.fixed 
                    ? 'Prezzo: +€${zone.value.toStringAsFixed(2)}' 
                    : 'Prezzo: +${zone.value.toStringAsFixed(0)}%',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showZoneEditor(context, zone: zone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteZone(context, dataService, zone),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showZoneEditor(BuildContext context, {BeachZone? zone}) {
    showDialog(
      context: context,
      builder: (context) => ZoneEditorDialog(zone: zone),
    );
  }

  void _deleteZone(BuildContext context, MockDataService dataService, BeachZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Zona'),
        content: Text('Sei sicuro di voler eliminare la zona "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              dataService.deleteZone(zone.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

class _PackagesTab extends StatelessWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final packages = dataService.packages;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return Card(
          child: ListTile(
            title: Text(package.name),
            subtitle: Text('${package.description}\nPrezzo Base: €${package.defaultBasePrice}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditPackageDialog(context, package),
            ),
          ),
        );
      },
    );
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final rules = dataService.priceRules;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        String details = '';
        if (rule.daysOfWeek != null) details += 'Giorni: ${rule.daysOfWeek}\n';
        if (rule.startDate != null) details += 'Dal: ${DateFormat('dd/MM').format(rule.startDate!)} Al: ${DateFormat('dd/MM').format(rule.endDate!)}\n';

        return Card(
          child: ListTile(
            title: Text(rule.name),
            subtitle: Text(
              '${details}Variazione: ${rule.pricingType == PricingType.fixed ? "+€${rule.value.toStringAsFixed(2)}" : "+${rule.value.toStringAsFixed(0)}%"}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditPriceRuleDialog(context, rule),
            ),
          ),
        );
      },
    );
  }
}

// Helper functions for editing
void _showEditPackageDialog(BuildContext context, ServicePackage package) {
  final nameController = TextEditingController(text: package.name);
  final descController = TextEditingController(text: package.description);
  final priceController = TextEditingController(text: package.defaultBasePrice.toString());

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Modifica Pacchetto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome Pacchetto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Prezzo Base (€)',
                border: OutlineInputBorder(),
                prefixText: '€ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: Le modifiche ai pacchetti sono solo dimostrative in questa versione demo.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pacchetto "${nameController.text}" aggiornato! (Demo)'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('Salva'),
        ),
      ],
    ),
  );
}

void _showEditPriceRuleDialog(BuildContext context, PriceRule rule) {
  final nameController = TextEditingController(text: rule.name);
  final valueController = TextEditingController(text: rule.value.toString());
  PricingType pricingType = rule.pricingType;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Modifica Regola Prezzo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Regola',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PricingType>(
                initialValue: pricingType,
                decoration: const InputDecoration(
                  labelText: 'Tipo Variazione',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PricingType.fixed,
                    child: Text('Importo Fisso (€)'),
                  ),
                  DropdownMenuItem(
                    value: PricingType.percentage,
                    child: Text('Percentuale (%)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => pricingType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: pricingType == PricingType.fixed ? 'Valore (€)' : 'Valore (%)',
                  border: const OutlineInputBorder(),
                  prefixText: pricingType == PricingType.fixed ? '€ ' : '',
                  suffixText: pricingType == PricingType.percentage ? '%' : '',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nota: Le modifiche alle regole sono solo dimostrative in questa versione demo.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Regola "${nameController.text}" aggiornata! (Demo)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    ),
  );
}
