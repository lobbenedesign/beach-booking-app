import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/beach_model.dart';

class BookingConfirmationTicket extends StatelessWidget {
  final String bookingId;
  final MapElement umbrella;
  final DateTime startDate;
  final DateTime endDate;
  final String customerName;
  final String packageName;
  final double subtotal;
  final double bookingFee;
  final double vat;
  final double paymentFee;
  final double total;
  final List<BookingExtra> extras;

  const BookingConfirmationTicket({
    super.key,
    required this.bookingId,
    required this.umbrella,
    required this.startDate,
    required this.endDate,
    required this.customerName,
    required this.packageName,
    required this.subtotal,
    required this.bookingFee,
    required this.vat,
    required this.paymentFee,
    required this.total,
    required this.extras,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Ticket Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Biglietto Prenotazione',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Ticket Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: bookingId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'ID: ${bookingId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Booking Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.person,
                            'Cliente',
                            customerName,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.beach_access,
                            'Ombrellone',
                            '${umbrella.row}-${umbrella.number}',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Dal',
                            _formatDate(startDate),
                          ),
                          _buildDetailRow(
                            Icons.event,
                            'Al',
                            _formatDate(endDate),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.inventory_2,
                            'Pacchetto',
                            packageName,
                          ),
                          
                          // Extras
                          if (extras.isNotEmpty) ...[
                            const Divider(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Extra:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...extras.map((extra) {
                              final days = extra.forDates?.length ??
                                  (endDate.difference(startDate).inDays + 1);
                              final daysLabel = extra.isPartialStay
                                  ? ' · $days gg'
                                  : '';
                              return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    extra.isService ? Icons.room_service : Icons.chair,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${extra.name} x${extra.quantity}$daysLabel',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '€${(extra.price * extra.quantity * days).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            }),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cost Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildCostRow('Subtotale', subtotal),
                          _buildCostRow('Commissione', bookingFee),
                          _buildCostRow('IVA', vat),
                          _buildCostRow('Costo Bonifico', paymentFee),
                          const Divider(height: 16),
                          _buildCostRow(
                            'TOTALE PAGATO',
                            total,
                            isBold: true,
                            isLarge: true,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Presenta questo QR code al check-in',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareTicket(),
                      icon: const Icon(Icons.share),
                      label: const Text('Condividi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Chiudi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isBold = false, bool isLarge = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isLarge ? 16 : 13,
              color: color,
            ),
          ),
          Text(
            '€${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isLarge ? 16 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareTicket() {
    final message = '''
🏖️ PRENOTAZIONE CONFERMATA - Lido Paradiso

📋 ID: ${bookingId.substring(0, 8).toUpperCase()}
👤 Cliente: $customerName
🏖️ Ombrellone: ${umbrella.row}-${umbrella.number}
📅 Dal: ${_formatDate(startDate)}
📅 Al: ${_formatDate(endDate)}
📦 Pacchetto: $packageName

💰 TOTALE: €${total.toStringAsFixed(2)}

✅ Presenta il QR code al check-in!
''';

    Share.share(
      message,
      subject: 'Prenotazione Lido Paradiso - ${bookingId.substring(0, 8).toUpperCase()}',
    );
  }
}
