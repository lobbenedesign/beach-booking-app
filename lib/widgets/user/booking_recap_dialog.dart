import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../services/mock_data_service.dart';
import '../../models/beach_model.dart';

class BookingRecapDialog extends StatefulWidget {
  final List<MapElement> umbrellas;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedPackageId;
  final String customerName;

  const BookingRecapDialog({
    super.key,
    required this.umbrellas,
    required this.startDate,
    required this.endDate,
    required this.selectedPackageId,
    required this.customerName,
  });

  @override
  State<BookingRecapDialog> createState() => _BookingRecapDialogState();
}

class _BookingRecapDialogState extends State<BookingRecapDialog> {
  final Map<String, int> _selectedEquipment = {};
  final Map<String, int> _selectedServices = {};
  bool _acceptedRegulations = false;
  bool _isLoading = false;

  // Coupon & deposit
  final TextEditingController _couponCtrl = TextEditingController();
  Coupon? _appliedCoupon;
  String? _couponError;
  bool _payDeposit = false;
  
  // Timer for Locking
  late Timer _timer;
  int _remainingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _handleTimeout();
      }
    });
  }
  
  void _handleTimeout() {
    _timer.cancel();
    Navigator.pop(context); // Close dialog
    // Unlock happens in caller or here?
    // We explicitly unlock here to be safe
    Provider.of<MockDataService>(context, listen: false)
        .unlockMultipleUmbrellas(widget.umbrellas.map((u) => u.id).toList());
        
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tempo scaduto! Gli ombrelloni sono stati rilasciati.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    _couponCtrl.dispose();
    super.dispose();
  }

  double _discountAmount() {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.discountFor(_calculateSubtotal());
  }

  double _depositAmount() {
    final data = Provider.of<MockDataService>(context, listen: false);
    return _calculateTotal() * (data.depositPercentage / 100);
  }

  double _amountDueNow() => _payDeposit ? _depositAmount() : _calculateTotal();

  void _applyCoupon() {
    final data = Provider.of<MockDataService>(context, listen: false);
    final coupon = data.validateCoupon(_couponCtrl.text);
    setState(() {
      if (coupon == null) {
        _appliedCoupon = null;
        _couponError = 'Codice non valido o scaduto';
      } else {
        _appliedCoupon = coupon;
        _couponError = null;
      }
    });
  }

  /// Each umbrella's own package price for the whole stay, computed from
  /// its own zone/season/weekday price list (`priceForPackageOnUmbrella`) —
  /// NOT a single shared price multiplied by umbrella count, since umbrellas
  /// in the same multi-selection can sit in different (differently priced)
  /// zones.
  Map<String, double> _pricePerUmbrella() {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    final days = widget.endDate.difference(widget.startDate).inDays + 1;
    return {
      for (final u in widget.umbrellas)
        u.id: List.generate(days, (i) => widget.startDate.add(Duration(days: i)))
            .map((day) => dataService.priceForPackageOnUmbrella(widget.selectedPackageId, u.id, day))
            .fold(0.0, (a, b) => a + b),
    };
  }

  double _packagesSubtotal() => _pricePerUmbrella().values.fold(0.0, (a, b) => a + b);

  double _extrasSubtotal() {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    double total = 0;
    for (var entry in _selectedEquipment.entries) {
      final equipment = dataService.extraEquipment.firstWhere((e) => e.id == entry.key);
      total += equipment.price * entry.value;
    }
    for (var entry in _selectedServices.entries) {
      final service = dataService.extraServices.firstWhere((s) => s.id == entry.key);
      total += service.price * entry.value;
    }
    return total;
  }

  double _calculateSubtotal() => _packagesSubtotal() + _extrasSubtotal();

  double _calculateBookingFee(double subtotal) {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    return subtotal * (dataService.bookingFeePercentage / 100);
  }

  double _calculateVAT(double subtotal) {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    return subtotal * (dataService.vatPercentage / 100);
  }

  double _calculateTotal() {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    final subtotal = _calculateSubtotal();
    final total = subtotal -
        _discountAmount() +
        _calculateBookingFee(subtotal) +
        _calculateVAT(subtotal) +
        dataService.paymentFee;
    return total < 0 ? 0 : total;
  }

  String _formatTimer() {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<MockDataService>(context);

    final umbrellasLabel = widget.umbrellas.map((u) => '${u.row}-${u.number}').join(', ');
    final settings = dataService.financialSettings;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
        child: Column(
          children: [
            // Header with Timer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60 ? Colors.red.shade700 : Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completa il pagamento',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tempo rimanente: ${_formatTimer()}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_remainingSeconds < 60)
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(8),
                         margin: const EdgeInsets.only(bottom: 16),
                         color: Colors.red.shade50,
                         child: const Text(
                           'Affrettati! Il tempo sta per scadere e gli ombrelloni verranno sbloccati.',
                           style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                           textAlign: TextAlign.center,
                         ),
                       ),
                  
                    // Booking Details
                    _buildSection(
                      'Riepilogo',
                      Icons.receipt,
                      [
                        _buildDetailRow('Ombrelloni', umbrellasLabel),
                        _buildDetailRow('Cliente', widget.customerName),
                        _buildDetailRow('Periodo', '${_formatDate(widget.startDate)} - ${_formatDate(widget.endDate)}'),
                        _buildDetailRow('Totale da Pagare', '€${_calculateTotal().toStringAsFixed(2)}', isBold: true, color: Colors.green.shade700),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    ExpansionTile( 
                      title: const Text('Aggiungi Extra'),
                      children: [
                         _buildSection(
                          'Attrezzatura Extra',
                          Icons.chair,
                          dataService.extraEquipment.map((e) => _buildExtraItem(e.name, e.price, e.id, true)).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Servizi Extra',
                          Icons.local_drink,
                          dataService.extraServices.map((s) => _buildExtraItem(s.name, s.price, s.id, false)).toList(),
                        ),
                      ],
                    ),

                    const Divider(height: 32),
                    
                    // Cost Breakdown
                    _buildCostBreakdown(),
                    
                    const Divider(height: 32),
                    
                     // Regulations
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dataService.facilityRegulations,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _acceptedRegulations,
                      onChanged: (value) => setState(() => _acceptedRegulations = value ?? false),
                      title: const Text('Accetto il regolamento della struttura'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            // Payment Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                     // Logic: Check if online payments are configured
                     if (settings.iban.isEmpty) ...[
                        // Online payments disabled (Visual only - Greyed out)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null, // Disabled
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Paga con Carta (Non disponibile)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null, // Disabled
                            icon: const Icon(Icons.payment),
                            label: const Text('PayPal (Non disponibile)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Manual Confirmation Button
                        const Text(
                          'Il pagamento sarà ultimato in struttura.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _acceptedRegulations ? () => _processTransaction(context, PaymentProvider.manual, 'MANUAL_${DateTime.now().millisecondsSinceEpoch}') : null,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Conferma Prenotazione'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                     ] else ...[
                         // Online Payments Enabled
                         if (settings.stripeEnabled)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _acceptedRegulations ? () => _showCardDialog(context) : null,
                              icon: const Icon(Icons.credit_card),
                              label: const Text('Paga con Carta (Stripe)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6772E5), // Stripe Blur
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (settings.paypalEnabled)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _acceptedRegulations ? () => _simulatePayPal(context) : null,
                                icon: const Icon(Icons.payment), // PayPal icon approx
                                label: const Text('Paga con PayPal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003087), // PayPal Blue
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                     ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildExtraItem(String name, double price, String id, bool isEquipment) {
     final selectedMap = isEquipment ? _selectedEquipment : _selectedServices;
     final quantity = selectedMap[id] ?? 0;
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text('$name (+€$price)'),
         Row(
           children: [
             IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: quantity > 0 ? () => setState(() => selectedMap[id] = quantity - 1) : null),
             Text('$quantity'),
             IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => selectedMap[id] = quantity + 1)),
           ],
         )
       ],
     );
  }
  
  Widget _buildCostBreakdown() {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    final subtotal = _calculateSubtotal();
    final discount = _discountAmount();
    final total = _calculateTotal();

    return Column(
      children: [
        // Coupon field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Codice sconto',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  errorText: _couponError,
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyCoupon,
              child: const Text('Applica'),
            ),
          ],
        ),
        if (_appliedCoupon != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text('Coupon "${_appliedCoupon!.code}" applicato',
                    style: const TextStyle(color: Colors.green)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _appliedCoupon = null;
                    _couponCtrl.clear();
                  }),
                  child: const Text('Rimuovi'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        _buildDetailRow('Subtotale', '€${subtotal.toStringAsFixed(2)}'),
        if (discount > 0)
          _buildDetailRow('Sconto', '-€${discount.toStringAsFixed(2)}',
              color: Colors.green),
        _buildDetailRow('Commissione servizio',
            '€${_calculateBookingFee(subtotal).toStringAsFixed(2)}'),
        _buildDetailRow(
            'IVA', '€${_calculateVAT(subtotal).toStringAsFixed(2)}'),
        _buildDetailRow(
            'Costi pagamento', '€${dataService.paymentFee.toStringAsFixed(2)}'),
        const Divider(),
        _buildDetailRow('Totale', '€${total.toStringAsFixed(2)}',
            isBold: true, color: Colors.green.shade700),

        // Deposit option
        const SizedBox(height: 8),
        SwitchListTile(
          value: _payDeposit,
          onChanged: (v) => setState(() => _payDeposit = v),
          contentPadding: EdgeInsets.zero,
          title: Text(
              'Paga solo l\'acconto (${dataService.depositPercentage.toStringAsFixed(0)}%)'),
          subtitle: _payDeposit
              ? Text(
                  'Ora: €${_depositAmount().toStringAsFixed(2)} • Saldo in struttura: €${(total - _depositAmount()).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600))
              : const Text('Salda il resto direttamente in spiaggia'),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime d) => '${d.day}/${d.month}';

  // --- Payment Flows ---

  void _showCardDialog(BuildContext mainContext) {
    // Show Simulated Stripe Card Input
    showDialog(
      context: mainContext,
      builder: (context) => _StripeCardDialog(
        amount: _amountDueNow(),
        onPay: () {
            Navigator.pop(context); // Close card dialog
            _processTransaction(mainContext, PaymentProvider.stripe, 'STRIPE_${DateTime.now().millisecondsSinceEpoch}');
        }
      ),
    );
  }
  
  void _simulatePayPal(BuildContext context) {
      setState(() => _isLoading = true);
      // Simulate redirection
      Future.delayed(const Duration(seconds: 2), () {
         _processTransaction(context, PaymentProvider.paypal, 'PAYPAL_${DateTime.now().millisecondsSinceEpoch}');
      });
  }

  void _processTransaction(BuildContext context, PaymentProvider provider, String ref) {
    final dataService = Provider.of<MockDataService>(context, listen: false);
    
    // Build extras list
    final List<BookingExtra> extras = [];
    _selectedEquipment.forEach((k, v) { if (v>0) {
        final e = dataService.extraEquipment.firstWhere((x) => x.id == k);
        extras.add(BookingExtra(id: e.id, name: e.name, price: e.price, quantity: v, isService: false));
    }});
    _selectedServices.forEach((k, v) { if (v>0) {
        final e = dataService.extraServices.firstWhere((x) => x.id == k);
        extras.add(BookingExtra(id: e.id, name: e.name, price: e.price, quantity: v, isService: true));
    }});
    
    final deposit = _payDeposit ? _depositAmount() : 0.0;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
        final result = dataService.createMultipleBookingsAndTransactions(
            pricePerUmbrella: _pricePerUmbrella(),
            packageId: widget.selectedPackageId,
            customerName: widget.customerName,
            startDate: widget.startDate,
            endDate: widget.endDate,
            extras: extras,
            extrasTotal: _extrasSubtotal(),
            bookingFeePercentage: dataService.bookingFeePercentage,
            vatPercentage: dataService.vatPercentage,
            paymentFeeTotal: dataService.paymentFee,
            provider: provider,
            paymentReference: ref,
            discountTotal: _discountAmount(),
            couponCode: _appliedCoupon?.code,
            depositTotal: deposit,
        );
        
        if (mounted) {
            setState(() => _isLoading = false);
            if (result['success']) {
                Navigator.pop(context, result);
            } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: ${result['message']}')));
            }
        }
    });
  }
}

class _StripeCardDialog extends StatelessWidget {
    final double amount;
    final VoidCallback onPay;
    
    _StripeCardDialog({required this.amount, required this.onPay});
    
    final _cardNumberFormatter = MaskTextInputFormatter(mask: '#### #### #### ####', filter: { "#": RegExp(r'[0-9]') });
    final _expiryFormatter = MaskTextInputFormatter(mask: '##/##', filter: { "#": RegExp(r'[0-9]') });
    final _cvcFormatter = MaskTextInputFormatter(mask: '###', filter: { "#": RegExp(r'[0-9]') });

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Row(children: [Icon(Icons.credit_card), SizedBox(width: 8), Text('Pagamento Stripe')]),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Text('Questa è una simulazione sicura.\nTotale: €${amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 16),
                        TextField(
                            decoration: const InputDecoration(labelText: 'Numero Carta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)),
                            keyboardType: TextInputType.number,
                            inputFormatters: [_cardNumberFormatter],
                        ),
                        const SizedBox(height: 12),
                        Row(
                            children: [
                                Expanded(child: TextField(
                                    decoration: const InputDecoration(labelText: 'MM/YY', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [_expiryFormatter],
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: TextField(
                                    decoration: const InputDecoration(labelText: 'CVC', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [_cvcFormatter],
                                )),
                            ]
                        ),
                    ]
                )
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                ElevatedButton(onPressed: onPay, child: const Text('Paga Ora')),
            ]
        );
    }
}
