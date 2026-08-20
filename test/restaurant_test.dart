import 'package:flutter_test/flutter_test.dart';
import 'package:beach_manager/models/restaurant_model.dart';
import 'package:beach_manager/services/mock_data_service.dart';
import 'package:beach_manager/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser => User(id: 'test_user', name: 'Test User', email: 'test@example.com');
}

void main() {
  late MockDataService dataService;

  setUp(() {
    dataService = MockDataService(FakeAuthService());
  });

  test('seeds a demo restaurant floor plan', () {
    expect(dataService.restaurantTables, isNotEmpty);
  });

  group('table booking collision guard', () {
    test('rejects a second booking on the same table/date/shift', () {
      final table = dataService.restaurantTables.first;
      final date = DateTime(2026, 8, 20);

      final first = TableBooking(
        id: 'tb1',
        tableId: table.id,
        userId: 'u1',
        customerName: 'Cliente A',
        date: date,
        shift: RestaurantShift.cena,
        partySize: 2,
      );
      expect(dataService.addTableBooking(first), isNull);

      final conflicting = TableBooking(
        id: 'tb2',
        tableId: table.id,
        userId: 'u2',
        customerName: 'Cliente B',
        date: date,
        shift: RestaurantShift.cena,
        partySize: 2,
      );
      final error = dataService.addTableBooking(conflicting);

      expect(error, isNotNull);
      expect(dataService.tableBookings.length, 1);
    });

    test('allows the same table on the same date but a different shift', () {
      final table = dataService.restaurantTables.first;
      final date = DateTime(2026, 8, 20);

      dataService.addTableBooking(TableBooking(
        id: 'tb1',
        tableId: table.id,
        userId: 'u1',
        customerName: 'Cliente A',
        date: date,
        shift: RestaurantShift.pranzo,
        partySize: 2,
      ));
      final error = dataService.addTableBooking(TableBooking(
        id: 'tb2',
        tableId: table.id,
        userId: 'u2',
        customerName: 'Cliente B',
        date: date,
        shift: RestaurantShift.cena,
        partySize: 2,
      ));

      expect(error, isNull);
      expect(dataService.tableBookings.length, 2);
    });
  });

  group('suggestTableFor', () {
    test('suggests the smallest table that fits the party', () {
      final date = DateTime(2026, 8, 21);
      final suggestion = dataService.suggestTableFor(date, RestaurantShift.cena, 4);

      expect(suggestion, isNotNull);
      expect(suggestion!.seats, greaterThanOrEqualTo(4));
      // Every smaller-or-equal available table should not exist, i.e. this
      // is the minimum seats among tables that fit.
      final smallerFits = dataService.restaurantTables
          .where((t) => t.seats >= 4 && t.seats < suggestion.seats)
          .where((t) => dataService.isTableAvailable(t.id, date, RestaurantShift.cena));
      expect(smallerFits, isEmpty);
    });

    test('returns null when no table is free', () {
      final date = DateTime(2026, 8, 22);
      for (final t in dataService.restaurantTables) {
        dataService.addTableBooking(TableBooking(
          id: 'tb_${t.id}',
          tableId: t.id,
          userId: 'u1',
          customerName: 'Filler',
          date: date,
          shift: RestaurantShift.pranzo,
          partySize: 1,
        ));
      }
      expect(dataService.suggestTableFor(date, RestaurantShift.pranzo, 2), isNull);
    });
  });

  group('cross-reference with beach bookings', () {
    test('userHasBeachBooking / userHasRestaurantBooking reflect actual state', () {
      expect(dataService.userHasBeachBooking('u1'), isFalse);
      expect(dataService.userHasRestaurantBooking('u1'), isFalse);

      final table = dataService.restaurantTables.first;
      dataService.addTableBooking(TableBooking(
        id: 'tb1',
        tableId: table.id,
        userId: 'u1',
        customerName: 'Cliente A',
        date: DateTime(2026, 8, 23),
        shift: RestaurantShift.cena,
        partySize: 2,
      ));

      expect(dataService.userHasRestaurantBooking('u1'), isTrue);
      expect(dataService.userHasBeachBooking('u1'), isFalse);
    });
  });

  test('TableBooking round-trips through toJson/fromJson', () {
    final original = TableBooking(
      id: 'tb1',
      tableId: 'table_1',
      userId: 'u1',
      customerName: 'Mario Rossi',
      date: DateTime(2026, 8, 20),
      shift: RestaurantShift.cena,
      partySize: 4,
      allergyNotes: 'Allergia ai crostacei',
      phone: '+39 333 1234567',
      status: TableBookingStatus.confirmed,
      checkedIn: true,
      createdAt: DateTime(2026, 8, 1, 9, 0),
    );

    final restored = TableBooking.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.tableId, original.tableId);
    expect(restored.customerName, original.customerName);
    expect(restored.date, original.date);
    expect(restored.shift, original.shift);
    expect(restored.partySize, original.partySize);
    expect(restored.allergyNotes, original.allergyNotes);
    expect(restored.checkedIn, original.checkedIn);
    expect(restored.createdAt, original.createdAt);
  });

  group('restaurant billing', () {
    test('addTableBooking preserves the cover-charge total and payment state', () {
      final table = dataService.restaurantTables.first;
      final booking = TableBooking(
        id: 'tb1',
        tableId: table.id,
        userId: 'u1',
        customerName: 'Cliente A',
        date: DateTime(2026, 8, 20),
        shift: RestaurantShift.cena,
        partySize: 4,
        totalPrice: 4 * dataService.restaurantCoverCharge,
      );
      dataService.addTableBooking(booking);

      final stored = dataService.tableBookings.first;
      expect(stored.totalPrice, 4 * dataService.restaurantCoverCharge);
      expect(stored.isPaid, isFalse);
      expect(stored.balanceDue, stored.totalPrice);
    });

    test('marking a booking as paid clears the balance due', () {
      final table = dataService.restaurantTables.first;
      dataService.addTableBooking(TableBooking(
        id: 'tb1',
        tableId: table.id,
        userId: 'u1',
        customerName: 'Cliente A',
        date: DateTime(2026, 8, 20),
        shift: RestaurantShift.cena,
        partySize: 2,
        totalPrice: 30,
      ));

      final booking = dataService.tableBookings.first;
      dataService.updateTableBooking(booking.copyWith(isPaid: true));

      final updated = dataService.tableBookings.first;
      expect(updated.isPaid, isTrue);
      expect(updated.balanceDue, 0);
    });

    test('a deposit leaves the remaining balance due', () {
      final booking = TableBooking(
        id: 'tb1',
        tableId: 't1',
        userId: 'u1',
        customerName: 'Cliente A',
        date: DateTime(2026, 8, 20),
        shift: RestaurantShift.cena,
        partySize: 2,
        totalPrice: 30,
        deposit: 10,
      );
      expect(booking.balanceDue, 20);
    });
  });

  group('restaurant zones', () {
    test('seeds Interno/Terrazza/Giardino and assigns every table to one', () {
      final zoneNames = dataService.restaurantZones.map((z) => z.name).toSet();
      expect(zoneNames, containsAll(['Interno', 'Terrazza', 'Giardino']));

      final zoneIds = dataService.restaurantZones.map((z) => z.id).toSet();
      for (final t in dataService.restaurantTables) {
        expect(t.zoneId, isNotNull, reason: 'Table ${t.id} has no zone');
        expect(zoneIds.contains(t.zoneId), isTrue,
            reason: 'Table ${t.id} has zoneId "${t.zoneId}" matching no RestaurantZone');
      }
    });

    test('deleting a zone clears zoneId on its tables instead of leaving a dangling reference', () {
      final zone = dataService.restaurantZones.first;
      final tablesInZone = dataService.restaurantTables.where((t) => t.zoneId == zone.id).toList();
      expect(tablesInZone, isNotEmpty);

      dataService.deleteRestaurantZone(zone.id);

      for (final t in tablesInZone) {
        expect(t.zoneId, isNull);
      }
      expect(dataService.restaurantZones.any((z) => z.id == zone.id), isFalse);
    });
  });
}
