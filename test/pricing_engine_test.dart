import 'package:flutter_test/flutter_test.dart';
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

  // Regression test for a real bug found in this codebase: seeded umbrellas
  // once had zoneId values ('vip'/'standard'/'economy') that didn't match
  // any seeded BeachZone id ('z1'/'z2'/'z3'), so the entire zone-based price
  // list was silently unreachable for every demo umbrella — packagesForUmbrella
  // and priceForPackageOnUmbrella always fell back to defaults, and the
  // "prices work per zone/season" feature appeared to work in isolated unit
  // tests (which construct their own data) but was dead in the actual seeded
  // app.
  test('every seeded umbrella has a zoneId that matches a real BeachZone', () {
    final zoneIds = dataService.zones.map((z) => z.id).toSet();
    for (final u in dataService.umbrellas) {
      expect(u.zoneId, isNotNull, reason: 'Umbrella ${u.id} has no zoneId at all');
      expect(zoneIds.contains(u.zoneId), isTrue,
          reason: 'Umbrella ${u.id} has zoneId "${u.zoneId}" which matches no BeachZone (${zoneIds.join(", ")})');
    }
  });

  test('packagesForUmbrella actually filters by zone for the seeded demo data (not falling back to all packages)', () {
    final umb = dataService.umbrellas.first;
    final filtered = dataService.packagesForUmbrella(umb.id);
    // The seed data configures a real, zone-specific price list — if this
    // ever returns every package unfiltered, the zoneId wiring is broken.
    expect(filtered.length, lessThan(dataService.packages.length));
  });

  test('priceForPackageOnUmbrella returns a real zone/season price, not just the flat default, for seeded umbrellas', () {
    final zoneOneUmbrella = dataService.umbrellas.firstWhere((u) => u.zoneId == 'z1');
    final zoneThreeUmbrella = dataService.umbrellas.firstWhere((u) => u.zoneId == 'z3');
    final activeSeason = dataService.activeSeasonOn(DateTime.now());
    // Only assert a concrete inequality when today actually falls inside a
    // configured season (the seed data's date ranges are relative to
    // "currentYear", so this is true most of the year but guard anyway).
    if (activeSeason == null) return;

    final priceZ1 = dataService.priceForPackageOnUmbrella('p1', zoneOneUmbrella.id, DateTime.now());
    final priceZ3 = dataService.priceForPackageOnUmbrella('p1', zoneThreeUmbrella.id, DateTime.now());
    expect(priceZ1, isNot(equals(priceZ3)), reason: 'Prima Fila (z1) and Standard (z3) must have different seeded prices');
  });

  test('a package with no price-list entry for a zone falls back to defaultBasePrice', () {
    final pkg = dataService.packages.firstWhere((p) => p.id == 'p2');
    // p2 only has a price-list entry for z1 in the seed data — on a z3
    // umbrella it must fall back to the package's flat default, not throw
    // or silently return 0.
    final zoneThreeUmbrella = dataService.umbrellas.firstWhere((u) => u.zoneId == 'z3');
    final price = dataService.priceForPackageOnUmbrella('p2', zoneThreeUmbrella.id, DateTime.now());
    expect(price, pkg.defaultBasePrice);
  });
}
