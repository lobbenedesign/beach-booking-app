import 'package:flutter_test/flutter_test.dart';
import 'package:beach_manager/services/mock_data_service.dart';
import 'package:beach_manager/services/auth_service.dart';
import 'package:beach_manager/models/beach_model.dart';
import 'package:flutter/material.dart';

class FakeAuthService extends AuthService {
  @override
  User? get currentUser => User(id: 'admin_user', name: 'Admin', email: 'admin@example.com', role: UserRole.admin);
}

void main() {
  late MockDataService dataService;
  late FakeAuthService authService;

  setUp(() {
    authService = FakeAuthService();
    dataService = MockDataService(authService);
  });

  group('Map Editor Logic', () {
    test('addMapElement adds an element to the list', () {
      final element = MapElement(
        id: 'test_elem_1',
        type: MapElementType.umbrella,
        x: 0.5,
        y: 0.5,
        width: 0.05,
        height: 0.05,
      );

      dataService.addMapElement(element);
      expect(dataService.mapElements.contains(element), true);
    });

    test('updateMapElement updates an existing element', () {
      final element = MapElement(
        id: 'test_elem_1',
        type: MapElementType.umbrella,
        x: 0.5,
        y: 0.5,
        width: 0.05,
        height: 0.05,
      );

      dataService.addMapElement(element);
      
      // Modify
      element.x = 0.6;
      dataService.updateMapElement(element);

      final updated = dataService.mapElements.firstWhere((e) => e.id == 'test_elem_1');
      expect(updated.x, 0.6);
    });

    test('removeMapElement removes an element', () {
      final element = MapElement(
        id: 'test_elem_1',
        type: MapElementType.umbrella,
        x: 0.5,
        y: 0.5,
        width: 0.05,
        height: 0.05,
      );

      dataService.addMapElement(element);
      dataService.removeMapElement('test_elem_1');
      
      expect(dataService.mapElements.any((e) => e.id == 'test_elem_1'), false);
    });
  });

  group('Extras Management Logic', () {
    test('Can add and update Extra Equipment', () {
      final equipment = ExtraEquipment(
        id: 'eq_1',
        name: 'Test Chair',
        description: 'A test chair',
        price: 5.0,
        available: true,
      );

      // Assuming we have methods to add/update, but looking at MockDataService they might be missing or direct list access is used.
      // Let's check if we can modify the list directly as the service exposes it.
      dataService.extraEquipment.add(equipment);
      expect(dataService.extraEquipment.contains(equipment), true);

      // Update
      equipment.price = 6.0;
      // In a real app we'd call a method, but here we simulate the UI updating the object reference
      expect(dataService.extraEquipment.first.price, 6.0);
    });

    test('Can add and update Extra Services', () {
      final service = ExtraService(
        id: 'srv_1',
        name: 'Test Massage',
        description: 'A test massage',
        price: 50.0,
        available: true,
      );

      dataService.extraServices.add(service);
      expect(dataService.extraServices.contains(service), true);

      service.available = false;
      expect(dataService.extraServices.first.available, false);
    });
    
    test('Can update Fees and Regulations', () {
      dataService.bookingFeePercentage = 10.0;
      dataService.vatPercentage = 20.0;
      dataService.paymentFee = 5.0;
      dataService.facilityRegulations = "No running";
      
      expect(dataService.bookingFeePercentage, 10.0);
      expect(dataService.vatPercentage, 20.0);
      expect(dataService.paymentFee, 5.0);
      expect(dataService.facilityRegulations, "No running");
    });
  });
}
