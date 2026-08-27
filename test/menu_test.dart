import 'package:flutter_test/flutter_test.dart';
import 'package:beach_booking/models/menu_model.dart';
import 'package:beach_booking/services/mock_data_service.dart';
import 'package:beach_booking/services/auth_service.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser => User(id: 'test_user', name: 'Test User', email: 'test@example.com');
}

void main() {
  late MockDataService dataService;

  setUp(() {
    dataService = MockDataService(FakeAuthService());
  });

  test('seeds the requested menu categories', () {
    final names = dataService.menuCategories.map((c) => c.name).toSet();
    expect(names, containsAll(['Antipasti', 'Pizze', 'Primi', 'Secondi', 'Dessert']));
  });

  test('every seeded item has a category, a price and belongs to a real category', () {
    final categoryIds = dataService.menuCategories.map((c) => c.id).toSet();
    for (final item in dataService.menuItems) {
      expect(categoryIds.contains(item.categoryId), isTrue, reason: '${item.name} has an orphan categoryId');
      expect(item.price, greaterThan(0));
    }
  });

  test('the risotto has a minimum order of 2', () {
    final risotto = dataService.menuItems.firstWhere((i) => i.id == 'risotto_pescatore');
    expect(risotto.hasMinimumOrder, isTrue);
    expect(risotto.minOrderQuantity, 2);
    expect(risotto.effectiveMinOrderNote, 'Minimo per 2 persone');
  });

  test('effectiveMinOrderNote derives a default when none is set', () {
    final item = MenuItem(id: 'x', categoryId: 'c', name: 'Test', price: 10, minOrderQuantity: 3);
    expect(item.effectiveMinOrderNote, 'Minimo 3 persone');
  });

  test('effectiveMinOrderNote is null when there is no minimum', () {
    final item = MenuItem(id: 'x', categoryId: 'c', name: 'Test', price: 10);
    expect(item.hasMinimumOrder, isFalse);
    expect(item.effectiveMinOrderNote, isNull);
  });

  test('menu item CRUD via the service', () {
    final item = MenuItem(
      id: 'new_dish',
      categoryId: 'antipasti',
      name: 'Carpaccio',
      price: 14,
      allergens: ['Pesce'],
    );
    dataService.addMenuItem(item);
    expect(dataService.menuItems.any((i) => i.id == 'new_dish'), isTrue);

    dataService.updateMenuItem(item.copyWith(price: 15, isAvailable: false));
    final updated = dataService.menuItems.firstWhere((i) => i.id == 'new_dish');
    expect(updated.price, 15);
    expect(updated.isAvailable, isFalse);

    dataService.deleteMenuItem('new_dish');
    expect(dataService.menuItems.any((i) => i.id == 'new_dish'), isFalse);
  });

  test('deleting a category also removes its items', () {
    final cat = MenuCategory(id: 'temp_cat', name: 'Temp');
    dataService.addMenuCategory(cat);
    dataService.addMenuItem(MenuItem(id: 'temp_item', categoryId: 'temp_cat', name: 'X', price: 5));

    dataService.deleteMenuCategory('temp_cat');

    expect(dataService.menuCategories.any((c) => c.id == 'temp_cat'), isFalse);
    expect(dataService.menuItems.any((i) => i.id == 'temp_item'), isFalse);
  });
}
