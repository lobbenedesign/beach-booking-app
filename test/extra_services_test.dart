import 'package:flutter_test/flutter_test.dart';
import 'package:beach_manager/models/extra_service_model.dart';
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

  test('seeds a demo extra services catalog across categories', () {
    expect(dataService.extraServiceItems, isNotEmpty);
    final categories = dataService.extraServiceItems.map((i) => i.category).toSet();
    expect(categories, containsAll(ExtraServiceCategory.values));
  });

  group('priceForExtraService', () {
    test('falls back to defaultPrice when no seasonal entry matches', () {
      final item = dataService.extraServiceItems.firstWhere((i) => i.id == 'bar_spritz');
      final price = dataService.priceForExtraService('bar_spritz', DateTime(2026, 1, 1));
      expect(price, item.defaultPrice);
    });

    test('uses the seasonal weekday/weekend price when a season entry exists', () {
      final season = dataService.seasons.firstWhere((s) => s.id == 's2'); // Alta Stagione
      final weekday = season.startDate.add(Duration(
          days: (8 - season.startDate.weekday) % 7)); // find a Monday within season
      final sunday = weekday.add(const Duration(days: 6));

      final weekdayPrice = dataService.priceForExtraService('rental_canoe_single', weekday);
      final sundayPrice = dataService.priceForExtraService('rental_canoe_single', sunday);

      expect(weekdayPrice, 10.0);
      expect(sundayPrice, 15.0);
      expect(sundayPrice, greaterThan(weekdayPrice));
    });
  });

  group('placeExtraServiceOrder', () {
    test('creates a pending order with the resolved total price and a notification', () {
      final beforeNotifications = dataService.notifications.length;
      final order = dataService.placeExtraServiceOrder(
        userId: 'u1',
        customerName: 'Mario Rossi',
        itemId: 'bar_spritz',
        quantity: 2,
        umbrellaId: dataService.umbrellas.first.id,
      );

      expect(order.status, ExtraOrderStatus.pending);
      expect(order.totalPrice, 6.0 * 2);
      expect(dataService.extraServiceOrders.first.id, order.id); // newest first
      expect(dataService.pendingExtraOrdersCount, 1);
      expect(dataService.notifications.length, beforeNotifications + 1);
    });

    test('updateExtraOrderStatus moves an order out of the pending count', () {
      final order = dataService.placeExtraServiceOrder(
        userId: 'u1',
        customerName: 'Mario Rossi',
        itemId: 'service_massage',
      );
      expect(dataService.pendingExtraOrdersCount, 1);

      dataService.updateExtraOrderStatus(order.id, ExtraOrderStatus.confirmed);
      expect(dataService.pendingExtraOrdersCount, 0);
      expect(dataService.extraServiceOrders.first.status, ExtraOrderStatus.confirmed);
    });
  });

  test('ExtraServiceOrder round-trips through toJson/fromJson', () {
    final original = ExtraServiceOrder(
      id: 'o1',
      userId: 'u1',
      customerName: 'Mario Rossi',
      itemId: 'bar_spritz',
      quantity: 3,
      umbrellaId: 'umb_0_0',
      totalPrice: 18.0,
      notes: 'Senza ghiaccio',
      status: ExtraOrderStatus.confirmed,
    );
    final restored = ExtraServiceOrder.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.customerName, original.customerName);
    expect(restored.itemId, original.itemId);
    expect(restored.quantity, original.quantity);
    expect(restored.umbrellaId, original.umbrellaId);
    expect(restored.totalPrice, original.totalPrice);
    expect(restored.notes, original.notes);
    expect(restored.status, original.status);
  });
}
