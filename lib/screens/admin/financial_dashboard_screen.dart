import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';
import '../../widgets/admin/admin_scaffold.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> with SingleTickerProviderStateMixin {
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
      title: 'Contabilità e Pagamenti',
      selectedIndex: 7,
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
                Tab(icon: Icon(Icons.insights), text: 'Analisi'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Transazioni'),
                Tab(icon: Icon(Icons.settings), text: 'Impostazioni Fiscali'),
                Tab(icon: Icon(Icons.policy), text: 'Policy & Compliance'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AnalyticsTab(),
                _TransactionsTab(),
                _SettingsTab(),
                 _PoliciesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<MockDataService>(context);
    final series = data.revenueLastDays(7);
    final maxVal = series.fold<double>(
        1, (m, e) => e.value > m ? e.value : m);
    final weekTotal = series.fold<double>(0, (s, e) => s + e.value);
    final avgOccupancy = data.occupancyRate();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
                child: _kpi('Incasso oggi',
                    '€${data.revenueToday.toStringAsFixed(2)}', Colors.green)),
            const SizedBox(width: 16),
            Expanded(
                child: _kpi('Incasso mese',
                    '€${data.revenueThisMonth.toStringAsFixed(2)}', Colors.blue)),
            const SizedBox(width: 16),
            Expanded(
                child: _kpi('Occupazione oggi',
                    '${(avgOccupancy * 100).toStringAsFixed(0)}%', Colors.orange)),
          ],
        ),
        const SizedBox(height: 32),
        Text('Incasso ultimi 7 giorni',
            style: Theme.of(context).textTheme.titleLarge),
        Text('Totale settimana: €${weekTotal.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        SizedBox(
          height: 240,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: series.map((e) {
              final ratio = e.value / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('€${e.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        height: (160 * ratio).clamp(4, 160).toDouble(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(DateFormat('E', 'it_IT').format(e.key),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);
    final transactions = dataService.transactions;
    // Sort desc
    final sortedTransactions = List<Transaction>.from(transactions)..sort((a, b) => b.date.compareTo(a.date));

    final totalRevenue = sortedTransactions.where((t) => t.status == 'completed').fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Incasso Totale', '€${totalRevenue.toStringAsFixed(2)}', Icons.euro, Colors.green),
              _buildSummaryCard('Transazioni Oggi', '${sortedTransactions.where((t) => isSameDay(t.date, DateTime.now())).length}', Icons.receipt, Colors.blue),
              _buildSummaryCard('Da incassare', '€${(sortedTransactions.where((t) => t.status != 'completed').fold(0.0, (sum, t) => sum + t.amount)).toStringAsFixed(2)}', Icons.euro, Colors.orange),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedTransactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final tx = sortedTransactions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: tx.provider == PaymentProvider.stripe 
                      ? Colors.deepPurple 
                      : (tx.provider == PaymentProvider.paypal ? Colors.blue : Colors.grey),
                  child: Icon(
                    tx.provider == PaymentProvider.stripe 
                        ? Icons.credit_card 
                        : (tx.provider == PaymentProvider.paypal ? Icons.payment : Icons.money),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text('Prenotazione: ${tx.bookingId.substring(0, 8)}...'),
                subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(tx.date)} • Rif: ${tx.externalReference ?? "N/A"}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+€${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    Text(
                      tx.status.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _ibanController;
  late TextEditingController _companyController;
  late TextEditingController _vatController;
  late TextEditingController _addressController;
  
  late TextEditingController _stripeKeyController;
  late TextEditingController _stripeSecretController;
  late TextEditingController _paypalClientController;
  late TextEditingController _paypalSecretController;
  
  bool _stripeEnabled = false;
  bool _paypalEnabled = false;
  double _depositPercentage = 30;

  @override
  void initState() {
    super.initState();
    final service = Provider.of<MockDataService>(context, listen: false);
    _depositPercentage = service.depositPercentage;
    final settings = service.financialSettings;
    _ibanController = TextEditingController(text: settings.iban);
    _companyController = TextEditingController(text: settings.companyName);
    _vatController = TextEditingController(text: settings.companyVatNumber);
    _addressController = TextEditingController(text: settings.companyAddress);
    
    _stripeKeyController = TextEditingController(text: settings.stripePublicKey);
    _stripeSecretController = TextEditingController(text: settings.stripeSecretKey);
    _paypalClientController = TextEditingController(text: settings.paypalClientId);
    _paypalSecretController = TextEditingController(text: settings.paypalSecret);
    
    _stripeEnabled = settings.stripeEnabled;
    _paypalEnabled = settings.paypalEnabled;
  }
  
  @override
  void dispose() {
    _ibanController.dispose();
    _companyController.dispose();
    _vatController.dispose();
    _addressController.dispose();
    _stripeKeyController.dispose();
    _stripeSecretController.dispose();
    _paypalClientController.dispose();
    _paypalSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Dati Fiscali Azienda'),
          const SizedBox(height: 16),
          TextField(controller: _companyController, decoration: const InputDecoration(labelText: 'Ragione Sociale', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _vatController, decoration: const InputDecoration(labelText: 'Partita IVA', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Indirizzo Sede Legale', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _ibanController, decoration: const InputDecoration(labelText: 'IBAN (per accredito bonifici)', border: OutlineInputBorder())),
          
          const SizedBox(height: 32),
          _buildSectionTitle('Gateway di Pagamento'),
          
          // Stripe
          SwitchListTile(
            title: const Text('Stripe', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Abilita pagamenti con Carta di Credito'),
            value: _stripeEnabled,
            onChanged: (val) => setState(() => _stripeEnabled = val),
          ),
          if (_stripeEnabled) ...[
            TextField(controller: _stripeKeyController, decoration: const InputDecoration(labelText: 'Stripe Public Key', border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key))),
            const SizedBox(height: 8),
            TextField(controller: _stripeSecretController, obscureText: true, decoration: const InputDecoration(labelText: 'Stripe Secret Key', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
          ],
          
          const Divider(height: 32),
          
          // PayPal
          SwitchListTile(
            title: const Text('PayPal', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Abilita pagamenti con PayPal'),
            value: _paypalEnabled,
            onChanged: (val) => setState(() => _paypalEnabled = val),
          ),
          if (_paypalEnabled) ...[
             TextField(controller: _paypalClientController, decoration: const InputDecoration(labelText: 'PayPal Client ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
             const SizedBox(height: 8),
             TextField(controller: _paypalSecretController, obscureText: true, decoration: const InputDecoration(labelText: 'PayPal Secret', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
          ],
          
          const SizedBox(height: 32),
          _buildSectionTitle('Sconti & Acconto'),
          const SizedBox(height: 8),
          Text('Acconto richiesto online: ${_depositPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _depositPercentage,
            min: 10,
            max: 100,
            divisions: 18,
            label: '${_depositPercentage.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _depositPercentage = v),
          ),
          const SizedBox(height: 8),
          _buildCouponsSection(),

          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Salva Impostazioni'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Consumer<MockDataService>(
      builder: (context, data, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Codici Sconto',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddCouponDialog(context, data),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuovo'),
                ),
              ],
            ),
            if (data.coupons.isEmpty)
              const Text('Nessun coupon attivo',
                  style: TextStyle(color: Colors.grey))
            else
              ...data.coupons.map((c) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: Colors.orange),
                      title: Text(c.code,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c.type == PricingType.percentage
                          ? 'Sconto ${c.value.toStringAsFixed(0)}%'
                          : 'Sconto €${c.value.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => data.deleteCoupon(c.code),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }

  void _showAddCouponDialog(BuildContext context, MockDataService data) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    PricingType type = PricingType.percentage;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nuovo Coupon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Codice'),
              ),
              DropdownButtonFormField<PricingType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: PricingType.percentage, child: Text('Percentuale (%)')),
                  DropdownMenuItem(
                      value: PricingType.fixed, child: Text('Importo fisso (€)')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? type),
              ),
              TextField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Valore'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () {
                final code = codeCtrl.text.trim().toUpperCase();
                final value =
                    double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0;
                if (code.isEmpty || value <= 0) return;
                data.addCoupon(Coupon(code: code, type: type, value: value));
                Navigator.pop(context);
              },
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveSettings() {
    final newSettings = FinancialSettings(
      companyName: _companyController.text,
      companyVatNumber: _vatController.text,
      companyAddress: _addressController.text,
      iban: _ibanController.text,
      stripeEnabled: _stripeEnabled,
      stripePublicKey: _stripeKeyController.text,
      stripeSecretKey: _stripeSecretController.text,
      paypalEnabled: _paypalEnabled,
      paypalClientId: _paypalClientController.text,
      paypalSecret: _paypalSecretController.text,
    );
    
    final service = Provider.of<MockDataService>(context, listen: false);
    service.updateFinancialSettings(newSettings);
    service.depositPercentage = _depositPercentage;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impostazioni salvate con successo!')));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87));
  }
}

class _PoliciesTab extends StatelessWidget {
  const _PoliciesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text('Policy & Compliance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stripe - Termini di Servizio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Assicurati di rispettare le normative PSD2 e SCA per i pagamenti in Europa. Le transazioni devono essere sicure e i dati delle carte non devono mai essere salvati sui nostri server locali, ma gestiti tramite token sicuri forniti da Stripe. Il sistema attuale implementa la tokenizzazione lato client.\n\nCommissioni standard: 1.4% + €0.25 per carte europee.'),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PayPal - User Agreement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('I pagamenti PayPal sono soggetti alla protezione acquisti. Assicurati che la "Ragione Sociale" inserita nelle impostazioni corrisponda a quella del conto Business associato.\n\nCommissioni standard: 3.4% + €0.35.'),
              ],
            ),
          ),
        ),
         SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Normativa Fiscale Locale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('L\'emissione dello scontrino elettronico/ricevuta deve avvenire contestualmente al pagamento. Questo sistema registra la transazione, ma l\'invio telematico dei corrispettivi deve essere gestito tramite registratore di cassa telematico o integrazione specifica (non attiva in questa demo).'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
