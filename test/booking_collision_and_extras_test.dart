import 'package:flutter_test/flutter_test.dart';
import 'package:beach_manager/models/beach_model.dart';
import 'package:beach_manager/services/mock_data_service.dart';
import 'package:beach_manager/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser =>
      User(id: 'test_user', name: 'Test User', email: 'test@example.com');
}

void main() {
  late MockDataService dataService;

  setUp(() {
    dataService = MockDataService(FakeAuthService());
  });

  group('addBooking (operator manual entry) collision guard', () {
    test('rejects a second booking overlapping an existing one', () {
      final start = DateTime(2026, 8, 10);
      final end = DateTime(2026, 8, 15);

      final first = Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente A',
        startDate: start,
        endDate: end,
        channel: BookingChannel.onSite,
        totalPrice: 100,
      );
      expect(dataService.addBooking(first), isNull);

      final overlapping = Booking(
        id: 'b2',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente B',
        startDate: DateTime(2026, 8, 12),
        endDate: DateTime(2026, 8, 18),
        channel: BookingChannel.onSite,
        totalPrice: 100,
      );
      final error = dataService.addBooking(overlapping);

      expect(error, isNotNull);
      expect(dataService.bookings.length, 1,
          reason: 'the overlapping booking must not have been saved');
    });

    test('accepts a non-overlapping booking on the same umbrella', () {
      final first = Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente A',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 12),
        channel: BookingChannel.onSite,
        totalPrice: 60,
      );
      final second = Booking(
        id: 'b2',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente B',
        startDate: DateTime(2026, 8, 13),
        endDate: DateTime(2026, 8, 15),
        channel: BookingChannel.onSite,
        totalPrice: 60,
      );

      expect(dataService.addBooking(first), isNull);
      expect(dataService.addBooking(second), isNull);
      expect(dataService.bookings.length, 2);
    });
  });

  group('updateBooking collision guard', () {
    test('rejects moving a booking onto an umbrella that is already booked', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente A',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 15),
        totalPrice: 100,
      ));
      dataService.addBooking(Booking(
        id: 'b2',
        umbrellaId: 'umb_1_2',
        userId: 'manual_entry',
        customerName: 'Cliente B',
        startDate: DateTime(2026, 8, 12),
        endDate: DateTime(2026, 8, 14),
        totalPrice: 100,
      ));

      final moved = dataService.bookings
          .firstWhere((b) => b.id == 'b2')
          .copyWith(umbrellaId: 'umb_1_1');
      final error = dataService.updateBooking(moved);

      expect(error, isNotNull);
      expect(dataService.bookings.firstWhere((b) => b.id == 'b2').umbrellaId,
          'umb_1_2', reason: 'booking must remain on its original umbrella');
    });
  });

  group('bookingsForUmbrellaInRange (dashboard beach map)', () {
    test('finds bookings intersecting a multi-day range', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'manual_entry',
        customerName: 'Cliente A',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 12),
        totalPrice: 60,
      ));

      final inRange = dataService.bookingsForUmbrellaInRange(
          'umb_1_1', DateTime(2026, 8, 11), DateTime(2026, 8, 20));
      final outOfRange = dataService.bookingsForUmbrellaInRange(
          'umb_1_1', DateTime(2026, 8, 13), DateTime(2026, 8, 20));

      expect(inRange.length, 1);
      expect(outOfRange, isEmpty);
    });
  });

  group('seasonal / last-minute classification', () {
    test('a 21+ day stay is seasonal', () {
      final b = Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 1),
        totalPrice: 500,
      );
      expect(b.isSeasonal, isTrue);
      expect(b.isLastMinute, isFalse);
    });

    test('a short stay booked right before arrival is last-minute', () {
      final now = DateTime.now();
      final b = Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: now.add(const Duration(hours: 5)),
        endDate: now.add(const Duration(hours: 5)),
        totalPrice: 20,
        createdAt: now,
      );
      expect(b.isLastMinute, isTrue);
      expect(b.isSeasonal, isFalse);
    });

    test('a short stay booked weeks in advance is neither', () {
      final b = Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 21),
        totalPrice: 40,
        createdAt: DateTime(2026, 7, 1),
      );
      expect(b.isLastMinute, isFalse);
      expect(b.isSeasonal, isFalse);
    });
  });

  group('addExtraToBooking (equipment for specific days)', () {
    test('adding an extra for the whole stay multiplies by every day', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 13), // 4 days
        totalPrice: 100,
        subtotal: 100,
      ));

      final error = dataService.addExtraToBooking(
        bookingId: 'b1',
        id: 'lettino',
        name: 'Lettino',
        price: 5,
        isService: false,
      );

      final updated = dataService.bookings.first;
      expect(error, isNull);
      expect(updated.totalPrice, 120); // 100 + 5*4 days
      expect(updated.extras.single.isPartialStay, isFalse);
    });

    test('adding an extra for only 2 of the days only charges those days', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 13), // 4 days
        totalPrice: 100,
        subtotal: 100,
      ));

      final error = dataService.addExtraToBooking(
        bookingId: 'b1',
        id: 'sedia',
        name: 'Sedia',
        price: 3,
        isService: false,
        forDates: [DateTime(2026, 8, 11), DateTime(2026, 8, 12)],
      );

      final updated = dataService.bookings.first;
      expect(error, isNull);
      expect(updated.totalPrice, 106); // 100 + 3*2 days
      expect(updated.extras.single.isPartialStay, isTrue);
    });

    test('rejects a day outside the booking period', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 13),
        totalPrice: 100,
        subtotal: 100,
      ));

      final error = dataService.addExtraToBooking(
        bookingId: 'b1',
        id: 'sedia',
        name: 'Sedia',
        price: 3,
        isService: false,
        forDates: [DateTime(2026, 9, 1)],
      );

      expect(error, isNotNull);
      expect(dataService.bookings.first.totalPrice, 100);
    });

    test('removeExtraFromBooking refunds the exact cost added', () {
      dataService.addBooking(Booking(
        id: 'b1',
        umbrellaId: 'umb_1_1',
        userId: 'u',
        customerName: 'Cliente',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 13),
        totalPrice: 100,
        subtotal: 100,
      ));
      dataService.addExtraToBooking(
        bookingId: 'b1',
        id: 'sedia',
        name: 'Sedia',
        price: 3,
        isService: false,
        forDates: [DateTime(2026, 8, 11)],
      );
      expect(dataService.bookings.first.totalPrice, 103);

      dataService.removeExtraFromBooking('b1', 0);
      expect(dataService.bookings.first.totalPrice, 100);
      expect(dataService.bookings.first.extras, isEmpty);
    });
  });
}
