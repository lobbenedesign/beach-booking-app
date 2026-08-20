import 'package:flutter/material.dart';
import '../../screens/user/my_bookings_screen.dart';

class BookingSuccessDialog extends StatelessWidget {
  final List<String>? bookingIds;
  final String? bookingId; // Keep for backward compatibility if needed, or remove

  const BookingSuccessDialog({
    super.key,
    this.bookingIds,
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the ID list to pass
    final idsToPass = bookingIds ?? (bookingId != null ? [bookingId!] : null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Prenotazione Confermata!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              idsToPass != null && idsToPass.length > 1 
                  ? 'Le tue ${idsToPass.length} prenotazioni sono avvenute con successo.'
                  : 'La tua prenotazione è avvenuta con successo.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vai a "Le Mie Prenotazioni" per vedere il riepilogo e trovare il biglietto.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Close dialogs and navigate to My Bookings
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyBookingsScreen(
                        highlightBookingIds: idsToPass,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Vai a Le Mie Prenotazioni'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Torna alla Home'),
            ),
          ],
        ),
      ),
    );
  }
}
