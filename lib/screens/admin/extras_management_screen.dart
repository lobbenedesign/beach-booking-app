import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';

import '../../widgets/admin/admin_scaffold.dart';

class ExtrasManagementScreen extends StatefulWidget {
  const ExtrasManagementScreen({super.key});

  @override
  State<ExtrasManagementScreen> createState() => _ExtrasManagementScreenState();
}

class _ExtrasManagementScreenState extends State<ExtrasManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Gestione Servizi Extra',
      selectedIndex: 4,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(icon: Icon(Icons.chair), text: 'Attrezzatura'),
                Tab(icon: Icon(Icons.room_service), text: 'Servizi'),
                Tab(icon: Icon(Icons.euro), text: 'Fee & IVA'),
                Tab(icon: Icon(Icons.gavel), text: 'Regolamento'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _EquipmentTab(),
                _ServicesTab(),
                _FeesTab(),
                _RegulationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Equipment Tab
class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestisci l\'attrezzatura extra disponibile per i clienti',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEquipmentDialog(context, dataService),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dataService.allExtraEquipment.length,
            itemBuilder: (context, index) {
              final equipment = dataService.allExtraEquipment[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: equipment.available ? Colors.green : Colors.grey,
                    child: const Icon(
                      Icons.chair,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(equipment.name),
                  subtitle: Text(equipment.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '€${equipment.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditEquipmentDialog(context, equipment),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEquipmentDialog(BuildContext context, MockDataService dataService) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Attrezzatura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
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
                  labelText: 'Prezzo (€)',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final price = double.tryParse(
                      priceController.text.replaceAll(',', '.')) ??
                  0.0;
              dataService.addExtraEquipment(ExtraEquipment(
                id: const Uuid().v4(),
                name: name,
                description: descController.text.trim(),
                price: price,
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attrezzatura aggiunta!')),
              );
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _showEditEquipmentDialog(BuildContext context, ExtraEquipment equipment) {
    final nameController = TextEditingController(text: equipment.name);
    final descController = TextEditingController(text: equipment.description);
    final priceController = TextEditingController(text: equipment.price.toString());
    bool available = equipment.available;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifica Attrezzatura'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
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
                    labelText: 'Prezzo (€)',
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Disponibile'),
                  value: available,
                  onChanged: (value) => setState(() => available = value),
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
                // Update equipment logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attrezzatura aggiornata!')),
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

// Services Tab
class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestisci i servizi extra disponibili per i clienti',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddServiceDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dataService.allExtraServices.length,
            itemBuilder: (context, index) {
              final service = dataService.allExtraServices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: service.available ? Colors.blue : Colors.grey,
                    child: const Icon(
                      Icons.room_service,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(service.name),
                  subtitle: Text(service.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '€${service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditServiceDialog(context, service),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Servizio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
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
                  labelText: 'Prezzo (€)',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
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
              // Add service logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servizio aggiunto!')),
              );
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, ExtraService service) {
    final nameController = TextEditingController(text: service.name);
    final descController = TextEditingController(text: service.description);
    final priceController = TextEditingController(text: service.price.toString());
    bool available = service.available;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifica Servizio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
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
                    labelText: 'Prezzo (€)',
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Disponibile'),
                  value: available,
                  onChanged: (value) => setState(() => available = value),
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
                // Update service logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Servizio aggiornato!')),
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

// Fees Tab
class _FeesTab extends StatefulWidget {
  const _FeesTab();

  @override
  State<_FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<_FeesTab> {
  late TextEditingController _bookingFeeController;
  late TextEditingController _vatController;
  late TextEditingController _paymentFeeController;

  @override
  void initState() {
    super.initState();
    final dataService = Provider.of<MockDataService>(context, listen: false);
    _bookingFeeController = TextEditingController(text: dataService.bookingFeePercentage.toString());
    _vatController = TextEditingController(text: dataService.vatPercentage.toString());
    _paymentFeeController = TextEditingController(text: dataService.paymentFee.toString());
  }

  @override
  void dispose() {
    _bookingFeeController.dispose();
    _vatController.dispose();
    _paymentFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impostazioni Fee e Tasse',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configura le commissioni e le tasse applicate alle prenotazioni',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          // Booking Fee
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.percent, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'Commissione Prenotazione',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bookingFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Percentuale (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      helperText: 'Commissione applicata sul subtotale',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // VAT
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'IVA',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vatController,
                    decoration: const InputDecoration(
                      labelText: 'Percentuale (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      helperText: 'Imposta sul valore aggiunto',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Fee
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.euro, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'Costo Bonifico',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paymentFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Importo Fisso (€)',
                      border: OutlineInputBorder(),
                      prefixText: '€ ',
                      helperText: 'Costo fisso per il bonifico',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                dataService.bookingFeePercentage = double.tryParse(_bookingFeeController.text) ?? 5.0;
                dataService.vatPercentage = double.tryParse(_vatController.text) ?? 22.0;
                dataService.paymentFee = double.tryParse(_paymentFeeController.text) ?? 2.0;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impostazioni salvate!')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva Modifiche'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Regulations Tab
class _RegulationsTab extends StatefulWidget {
  const _RegulationsTab();

  @override
  State<_RegulationsTab> createState() => _RegulationsTabState();
}

class _RegulationsTabState extends State<_RegulationsTab> {
  late TextEditingController _regulationsController;

  @override
  void initState() {
    super.initState();
    final dataService = Provider.of<MockDataService>(context, listen: false);
    _regulationsController = TextEditingController(text: dataService.facilityRegulations);
  }

  @override
  void dispose() {
    _regulationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Regolamento Struttura',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Modifica il regolamento che i clienti devono accettare prima di prenotare',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _regulationsController,
            decoration: const InputDecoration(
              labelText: 'Testo Regolamento',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 15,
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                dataService.facilityRegulations = _regulationsController.text;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Regolamento salvato!')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva Regolamento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
