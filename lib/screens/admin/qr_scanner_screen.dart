import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data_service.dart';

import '../../widgets/admin/admin_scaffold.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _checkOutMode = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _checkOutMode ? 'Check-out QR' : 'Check-in QR',
      selectedIndex: 1,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _modeButton('Check-in', !_checkOutMode,
                  () => setState(() => _checkOutMode = false)),
              _modeButton('Check-out', _checkOutMode,
                  () => setState(() => _checkOutMode = true)),
            ],
          ),
        ),
        IconButton(
          icon: Icon(cameraController.torchEnabled == TorchState.on
              ? Icons.flash_on
              : Icons.flash_off, color: Colors.white),
          onPressed: () => cameraController.toggleTorch(),
        ),
        IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          onPressed: () => cameraController.switchCamera(),
        ),
      ],
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                if (!_isProcessing) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleQrCode(context, barcode.rawValue!);
                      break;
                    }
                  }
                }
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                'Inquadra il QR Code della prenotazione',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.blue.shade700 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleQrCode(BuildContext context, String bookingId) {
    setState(() => _isProcessing = true);

    final dataService = Provider.of<MockDataService>(context, listen: false);
    final result = _checkOutMode
        ? dataService.validateCheckOut(bookingId)
        : dataService.validateCheckIn(bookingId);
    final actionLabel = _checkOutMode ? 'Check-out' : 'Check-in';

    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(
          result.isValid ? Icons.check_circle : Icons.error,
          color: result.isValid ? Colors.green : Colors.red,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: result.isValid ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.booking != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildBookingDetail('Cliente', result.booking!.customerName),
              _buildBookingDetail('Ombrellone',
                  dataService.umbrellaLabel(result.booking!.umbrellaId)),
              _buildBookingDetail('Prezzo',
                  '€${result.booking!.totalPrice.toStringAsFixed(2)}'),
              if (!_checkOutMode && result.booking!.balanceDue > 0)
                _buildBookingDetail('Saldo da incassare',
                    '€${result.booking!.balanceDue.toStringAsFixed(2)}',
                    highlight: true),
              _buildBookingDetail('Periodo',
                  '${_formatDate(result.booking!.startDate)} - ${_formatDate(result.booking!.endDate)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Chiudi'),
          ),
          if (result.isValid && result.booking != null)
            ElevatedButton(
              onPressed: () {
                if (_checkOutMode) {
                  dataService.performCheckOut(result.booking!.id);
                } else {
                  dataService.performCheckIn(result.booking!.id);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ $actionLabel completato!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Conferma $actionLabel'),
            ),
        ],
      ),
    ).then((_) {
      // Reset processing flag when dialog is dismissed
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  Widget _buildBookingDetail(String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.orange.shade800 : null,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
