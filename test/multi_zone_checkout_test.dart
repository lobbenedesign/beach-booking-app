import 'package:flutter_test/flutter_test.dart';
import 'package:beach_booking/models/beach_model.dart';
import 'package:beach_booking/services/mock_data_service.dart';
import 'package:beach_booking/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser => User(id: 'test_user', name: 'Test User', email: 'test@example.com');
}

/// A deterministic weekday (Monday) inside season [seasonId], so price
/// lookups don't depend on what day the test happens to run (the seeded
/// price list only differentiates zone prices for the "Bassa Stagione" /
/// "Alta Stagione" seasons — a date landing outside any priced season, e.g.
/// in "Settembre" which has no zone-specific price-list entries, would make
/// every zone silently fall back to the same defaultBasePrice).
DateTime weekdayInSeason(MockDataService dataService, String seasonId) {
  final season = dataService.seasons.firstWhere((s) => s.id == seasonId);
  final monday = season.startDate
      .add(Duration(days: (8 - season.startDate.weekday) % 7));
  return DateTime(monday.year, monday.month, monday.day);
}

void main() {
  late MockDataService dataService;

  setUp(() {
    dataService = MockDataService(FakeAuthService());
  });

  test('createMultipleBookingsAndTransactions prices each umbrella by its own zone', () {
    // Seed umbrellas belong to zones z1 (prima fila, higher price) and z3
    // (standard, lower price) per the default seed data / price list.
    final umb1 = dataService.umbrellas.firstWhere((u) => u.zoneId == 'z1');
    final umb3 = dataService.umbrellas.firstWhere((u) => u.zoneId == 'z3');
    // Use a fixed weekday inside "Bassa Stagione" (s1), the season whose
    // seeded price list actually differentiates z1 from z3, rather than
    // "today + N days" which drifts throughout the year and can land in an
    // unpriced season (a real flakiness bug this regression test caught).
    final start = weekdayInSeason(dataService, 's1');

    final priceZ1 = dataService.priceForPackageOnUmbrella('p1', umb1.id, start);
    final priceZ3 = dataService.priceForPackageOnUmbrella('p1', umb3.id, start);

    // Sanity: the two zones must actually have different prices for this
    // test to be meaningful (they do, per the seeded price list: z1=25/30/35/35
    // vs z3=15/20/25/25 for season s1).
    expect(priceZ1, isNot(equals(priceZ3)));

    final result = dataService.createMultipleBookingsAndTransactions(
      pricePerUmbrella: {umb1.id: priceZ1, umb3.id: priceZ3},
      packageId: 'p1',
      customerName: 'Cliente Test',
      startDate: start,
      endDate: start,
      extras: const [],
      extrasTotal: 0,
      bookingFeePercentage: 0,
      vatPercentage: 0,
      paymentFeeTotal: 0,
      provider: PaymentProvider.manual,
      paymentReference: 'ref1',
    );

    expect(result['success'], isTrue);
    final ids = result['bookingIds'] as List<String>;
    expect(ids.length, 2);

    final bookingZ1 = dataService.bookings.firstWhere((b) => b.umbrellaId == umb1.id);
    final bookingZ3 = dataService.bookings.firstWhere((b) => b.umbrellaId == umb3.id);

    // Each booking must carry ITS OWN umbrella's price, not a shared average.
    expect(bookingZ1.totalPrice, priceZ1);
    expect(bookingZ3.totalPrice, priceZ3);
    expect(bookingZ1.totalPrice, isNot(equals(bookingZ3.totalPrice)));
  });

  test('shared costs (extras, fees, discount) are pooled correctly across umbrellas', () {
    final umbrellas = dataService.umbrellas.take(2).toList();
    final date = weekdayInSeason(dataService, 's1');

    final pricePerUmbrella = {
      for (final u in umbrellas) u.id: dataService.priceForPackageOnUmbrella('p1', u.id, date),
    };
    final packageSubtotal = pricePerUmbrella.values.fold(0.0, (a, b) => a + b);

    final result = dataService.createMultipleBookingsAndTransactions(
      pricePerUmbrella: pricePerUmbrella,
      packageId: 'p1',
      customerName: 'Cliente Extras',
      startDate: date,
      endDate: date,
      extras: const [],
      extrasTotal: 20, // pooled extras cost, shared across both umbrellas
      bookingFeePercentage: 10,
      vatPercentage: 22,
      paymentFeeTotal: 2,
      provider: PaymentProvider.manual,
      paymentReference: 'ref2',
      discountTotal: 5,
    );

    expect(result['success'], isTrue);
    final ids = result['bookingIds'] as List<String>;
    final created = dataService.bookings.where((b) => ids.contains(b.id)).toList();

    // Grand total across both bookings must equal subtotal + fee + vat -
    // discount + paymentFee computed on the TRUE pooled subtotal (package +
    // extras), not double-counted or lost in the per-umbrella split.
    final grandSubtotal = packageSubtotal + 20;
    final expectedGrandTotal =
        grandSubtotal - 5 + grandSubtotal * 0.10 + grandSubtotal * 0.22 + 2;
    final actualGrandTotal = created.fold<double>(0, (s, b) => s + b.totalPrice);

    expect(actualGrandTotal, closeTo(expectedGrandTotal, 0.01));
  });

  test('single-umbrella booking still works exactly as before (no regression)', () {
    final umb = dataService.umbrellas.first;
    final start = weekdayInSeason(dataService, 's1');
    final price = dataService.priceForPackageOnUmbrella('p1', umb.id, start);

    final result = dataService.createMultipleBookingsAndTransactions(
      pricePerUmbrella: {umb.id: price},
      packageId: 'p1',
      customerName: 'Solo',
      startDate: start,
      endDate: start,
      extras: const [],
      extrasTotal: 0,
      bookingFeePercentage: 0,
      vatPercentage: 0,
      paymentFeeTotal: 0,
      provider: PaymentProvider.manual,
      paymentReference: 'ref3',
    );

    expect(result['success'], isTrue);
    final booking = dataService.bookings.firstWhere((b) => b.umbrellaId == umb.id);
    expect(booking.totalPrice, price);
  });
}
