import 'package:flutter_test/flutter_test.dart';
import 'package:beach_booking/models/beach_model.dart';

void main() {
  test('Booking round-trips through toJson/fromJson', () {
    final original = Booking(
      id: 'b1',
      umbrellaId: 'umb_1_1',
      userId: 'user_1',
      customerName: 'Mario Rossi',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 15),
      status: BookingStatus.confirmed,
      totalPrice: 250.0,
      isPaid: true,
      packageId: 'p1',
      extras: [
        BookingExtra(
          id: 'sedia',
          name: 'Sedia',
          price: 5,
          quantity: 2,
          isService: false,
          forDates: [DateTime(2026, 8, 11), DateTime(2026, 8, 12)],
        ),
      ],
      subtotal: 200,
      bookingFee: 5,
      vat: 20,
      paymentFee: 2,
      discountAmount: 10,
      couponCode: 'SUMMER10',
      deposit: 50,
      checkedIn: true,
      checkedOut: false,
      channel: BookingChannel.onSite,
      absentDates: [DateTime(2026, 8, 13)],
      shareCode: 'SH-ABC123',
      createdAt: DateTime(2026, 8, 1, 10, 30),
    );

    final restored = Booking.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.umbrellaId, original.umbrellaId);
    expect(restored.customerName, original.customerName);
    expect(restored.startDate, original.startDate);
    expect(restored.endDate, original.endDate);
    expect(restored.status, original.status);
    expect(restored.totalPrice, original.totalPrice);
    expect(restored.isPaid, original.isPaid);
    expect(restored.packageId, original.packageId);
    expect(restored.extras.length, 1);
    expect(restored.extras.first.name, 'Sedia');
    expect(restored.extras.first.forDates?.length, 2);
    expect(restored.subtotal, original.subtotal);
    expect(restored.couponCode, original.couponCode);
    expect(restored.deposit, original.deposit);
    expect(restored.checkedIn, original.checkedIn);
    expect(restored.channel, original.channel);
    expect(restored.absentDates.single, original.absentDates.single);
    expect(restored.shareCode, original.shareCode);
    expect(restored.createdAt, original.createdAt);
  });

  test('Booking.fromJson tolerates missing optional fields', () {
    final minimal = {
      'id': 'b2',
      'umbrellaId': 'umb_1_1',
      'userId': 'guest',
      'customerName': 'Test',
      'startDate': DateTime(2026, 8, 10).toIso8601String(),
      'endDate': DateTime(2026, 8, 10).toIso8601String(),
      'status': 'confirmed',
      'totalPrice': 20.0,
    };

    final restored = Booking.fromJson(minimal);

    expect(restored.id, 'b2');
    expect(restored.extras, isEmpty);
    expect(restored.isPaid, isFalse);
    expect(restored.channel, BookingChannel.online);
  });
}
