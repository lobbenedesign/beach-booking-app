import 'package:flutter_test/flutter_test.dart';
import 'package:beach_booking/models/beach_model.dart';
import 'package:beach_booking/services/mock_data_service.dart';
import 'package:beach_booking/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser => User(id: 'test_user', name: 'Test User', email: 'test@example.com');
}

void main() {
  late MockDataService dataService;
  late FakeAuthService authService;

  setUp(() {
    authService = FakeAuthService();
    dataService = MockDataService(authService);
  });

  Booking makeBooking(String id, DateTime start, DateTime end, {String customerName = 'Test User'}) {
    return Booking(
      id: id,
      umbrellaId: 'umb_1_1',
      userId: 'manual_entry',
      customerName: customerName,
      startDate: start,
      endDate: end,
      totalPrice: 100,
    );
  }

  test('isUmbrellaAvailable returns true when no bookings exist', () {
    final startDate = DateTime(2024, 8, 1);
    final endDate = DateTime(2024, 8, 5);
    expect(dataService.isUmbrellaAvailable('umb_1_1', startDate, endDate), true);
  });

  test('isUmbrellaAvailable returns false when booking overlaps', () {
    final startDate = DateTime(2024, 8, 1);
    final endDate = DateTime(2024, 8, 5);

    // First booking
    dataService.addBooking(makeBooking('b1', startDate, endDate));

    // Overlapping booking (same dates)
    expect(dataService.isUmbrellaAvailable('umb_1_1', startDate, endDate), false);

    // Overlapping booking (inside)
    expect(dataService.isUmbrellaAvailable('umb_1_1', DateTime(2024, 8, 2), DateTime(2024, 8, 3)), false);

    // Overlapping booking (start overlap)
    expect(dataService.isUmbrellaAvailable('umb_1_1', DateTime(2024, 7, 30), DateTime(2024, 8, 2)), false);

    // Overlapping booking (end overlap)
    expect(dataService.isUmbrellaAvailable('umb_1_1', DateTime(2024, 8, 4), DateTime(2024, 8, 7)), false);
  });

  test('isUmbrellaAvailable returns true when booking does not overlap', () {
    final startDate = DateTime(2024, 8, 1);
    final endDate = DateTime(2024, 8, 5);

    // First booking
    dataService.addBooking(makeBooking('b1', startDate, endDate));

    // Non-overlapping booking (before)
    expect(dataService.isUmbrellaAvailable('umb_1_1', DateTime(2024, 7, 25), DateTime(2024, 7, 31)), true);

    // Non-overlapping booking (after)
    expect(dataService.isUmbrellaAvailable('umb_1_1', DateTime(2024, 8, 6), DateTime(2024, 8, 10)), true);
  });

  test('addBooking fails if umbrella is not available', () {
    final startDate = DateTime(2024, 8, 1);
    final endDate = DateTime(2024, 8, 5);

    // First booking
    dataService.addBooking(makeBooking('b1', startDate, endDate));

    // Second booking (overlapping)
    final error = dataService.addBooking(
        makeBooking('b2', startDate, endDate, customerName: 'Test User 2'));

    expect(error, isNotNull);
    expect(error, contains('occupato'));
  });
}
