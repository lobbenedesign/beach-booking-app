import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/beach_model.dart';
import '../models/menu_model.dart';
import '../models/app_notification.dart';
import '../models/restaurant_model.dart';
import '../models/extra_service_model.dart';
import 'auth_service.dart';

/// localStorage key (web) / prefs key (other platforms) for the persisted
/// booking list. Bumping the suffix invalidates old, incompatibly-shaped data.
const String _bookingsStorageKey = 'beach_manager_bookings_v1';
const String _tableBookingsStorageKey = 'beach_manager_table_bookings_v1';
const String _extraOrdersStorageKey = 'beach_manager_extra_orders_v1';

class MockDataService extends ChangeNotifier {
  final AuthService authService;
  
  final List<UmbrellaLock> _umbrellaLocks = [];
  FinancialSettings _financialSettings = FinancialSettings();
  final List<Transaction> _transactions = [];

  // Restored Data Sources
  final List<MapElement> _mapElements = [];
  final List<Booking> _bookings = [];
  final List<BeachZone> _zones = [];
  final List<ServicePackage> _packages = [];
  final List<PriceRule> _priceRules = []; // Keeping for legacy/compatibility
  final List<ExtraEquipment> _extraEquipment = [];
  final List<ExtraService> _extraServices = [];
  
  // New Pricing Data
  final List<Season> _seasons = [];
  final List<PriceListEntry> _priceList = [];
  
  // Menu Data Sources
  final List<MenuCategory> _menuCategories = [];
  final List<MenuItem> _menuItems = [];
  final List<Order> _orders = [];

  // Notifications
  final List<AppNotification> _notifications = [];

  // Discount coupons
  final List<Coupon> _coupons = [];

  // Booking shares (partial-booking handoff between users)
  final List<BookingShare> _shares = [];

  // Service credit accrued by users (e.g. 30% for early absence notice)
  final Map<String, double> _serviceCredits = {};

  // Restaurant module
  final List<RestaurantTable> _restaurantTables = [];
  final List<TableBooking> _tableBookings = [];
  final List<RestaurantZone> _restaurantZones = [];

  // On-demand extra services marketplace (bar orders, timed rentals,
  // at-umbrella services) — see extra_service_model.dart.
  final List<ExtraServiceItem> _extraServiceItems = [];
  final List<ExtraPriceListEntry> _extraPriceList = [];
  final List<ExtraServiceOrder> _extraServiceOrders = [];

  // Percentage of the total requested as a deposit (acconto)
  double _depositPercentage = 30.0;

  // Fee Settings — private with notifying setters so screens already built
  // (e.g. a user mid-booking) pick up an admin's change immediately, not just
  // on the next unrelated rebuild.
  double _bookingFeePercentage = 5.0; // 5%
  double _vatPercentage = 22.0; // 22%
  double _paymentFee = 2.0; // €2.00 fixed
  double _restaurantCoverCharge = 15.0; // € per person (coperto), default suggestion
  String _facilityRegulations = '''
Regolamento Struttura:

1. Il check-in è dalle 9:00 alle 19:00
2. È vietato fumare nelle aree comuni
3. Gli animali devono essere tenuti al guinzaglio
4. Rispettare la quiete nelle ore di riposo (14:00-16:00)
5. Lasciare la postazione pulita alla partenza
6. Segnalare eventuali danni allo staff
''';

  double get bookingFeePercentage => _bookingFeePercentage;
  set bookingFeePercentage(double value) {
    _bookingFeePercentage = value;
    notifyListeners();
  }

  double get vatPercentage => _vatPercentage;
  set vatPercentage(double value) {
    _vatPercentage = value;
    notifyListeners();
  }

  double get paymentFee => _paymentFee;
  set paymentFee(double value) {
    _paymentFee = value;
    notifyListeners();
  }

  double get restaurantCoverCharge => _restaurantCoverCharge;
  set restaurantCoverCharge(double value) {
    _restaurantCoverCharge = value;
    notifyListeners();
  }

  String get facilityRegulations => _facilityRegulations;
  set facilityRegulations(String value) {
    _facilityRegulations = value;
    notifyListeners();
  }

  double get depositPercentage => _depositPercentage;
  set depositPercentage(double value) {
    _depositPercentage = value;
    notifyListeners();
  }

  // --- Coupons ---
  List<Coupon> get coupons => List.unmodifiable(_coupons);

  /// Returns the coupon if the code exists and is currently valid, else null.
  Coupon? validateCoupon(String code) {
    final c = _coupons
        .where((c) => c.code.toUpperCase() == code.trim().toUpperCase())
        .firstOrNull;
    if (c == null || !c.isValid) return null;
    return c;
  }

  void addCoupon(Coupon coupon) {
    _coupons.add(coupon);
    notifyListeners();
  }

  void deleteCoupon(String code) {
    _coupons.removeWhere((c) => c.code == code);
    notifyListeners();
  }

  List<MapElement> get mapElements => _mapElements;
  // Helper to get just umbrellas for legacy support/booking
  List<MapElement> get umbrellas => _mapElements.where((e) => e.type == MapElementType.umbrella).toList();

  // Custom beach background (data URL, e.g. "data:image/png;base64,...").
  // Shown instead of the procedural sand/sea painters when set — shared by
  // the map editor, the operator dashboard/daily map, and the customer
  // booking screen.
  String? _beachBackgroundImage;
  String? get beachBackgroundImage => _beachBackgroundImage;
  void setBeachBackgroundImage(String? dataUrl) {
    _beachBackgroundImage = dataUrl;
    notifyListeners();
  }

  // Human-readable label for an umbrella id (e.g. "A-5" or "2-3")
  String umbrellaLabel(String umbrellaId) {
    final u = _mapElements.where((e) => e.id == umbrellaId).firstOrNull;
    if (u == null) return umbrellaId;
    return u.label ?? '${u.row ?? '?'}-${u.number ?? '?'}';
  }
  
  List<Booking> get bookings => _bookings;
  List<BeachZone> get zones => _zones;
  List<ServicePackage> get packages => _packages;
  List<PriceRule> get priceRules => _priceRules;
  List<Season> get seasons => _seasons;
  List<PriceListEntry> get priceList => _priceList;
  List<ExtraEquipment> get extraEquipment => _extraEquipment.where((e) => e.available).toList();
  List<ExtraService> get extraServices => _extraServices.where((e) => e.available).toList();
  FinancialSettings get financialSettings => _financialSettings;
  List<Transaction> get transactions => _transactions;
  
  // Menu Getters
  List<MenuCategory> get menuCategories => _menuCategories;
  List<MenuItem> get menuItems => _menuItems;
  List<Order> get orders => _orders;

  // Notification Getters
  List<AppNotification> get notifications =>
      _notifications.reversed.toList(); // newest first
  int get unreadNotificationsCount => _notifications.where((n) => !n.read).length;

  void _pushNotification({
    required String title,
    required String body,
    required AppNotificationType type,
    String? refId,
  }) {
    _notifications.add(AppNotification(
      id: const Uuid().v4(),
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      refId: refId,
    ));
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final n = _notifications.where((n) => n.id == id).firstOrNull;
    if (n != null && !n.read) {
      n.read = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Guards against a race where an early notifyListeners() (fired while
  // seeding demo data, before the async storage read below resolves) would
  // persist an empty booking list and clobber whatever a previous session
  // had saved. Only starts persisting once hydration has had its say.
  bool _readyToPersistBookings = false;

  MockDataService(this.authService) {
    _initializeMockData();
    // Fire-and-forget: replace the freshly-seeded demo bookings with
    // whatever was persisted from a previous session, as soon as the async
    // storage read resolves.
    _hydrateBookingsFromStorage();
    _hydrateTableBookingsFromStorage();
    _hydrateExtraOrdersFromStorage();
  }

  /// Persists the current booking list so it survives a page reload.
  /// Called automatically on every [notifyListeners] — see override below —
  /// so any booking change (create, edit, extras, check-in, move, delete...)
  /// is saved in real time without every call site having to remember to.
  Future<void> _persistBookings() async {
    if (!_readyToPersistBookings) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _bookings.map((b) => b.toJson()).toList();
      await prefs.setString(_bookingsStorageKey, jsonEncode(jsonList));
    } catch (_) {
      // Best-effort: persistence is a convenience, never block the UI on it.
    }
  }

  Future<void> _hydrateBookingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_bookingsStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final restored = decoded
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList();
        _bookings
          ..clear()
          ..addAll(restored);
      }
    } catch (_) {
      // Corrupt/incompatible stored data: keep the freshly-seeded demo state.
    } finally {
      _readyToPersistBookings = true;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _persistBookings();
    _persistTableBookings();
    _persistExtraOrders();
  }

  void updateFinancialSettings(FinancialSettings settings) {
    _financialSettings = settings;
    notifyListeners();
  }

  // --- Locking Methods ---
  
  // Try to lock an umbrella for 5 minutes
  bool lockUmbrella(String umbrellaId, String userId) {
    cleanupExpiredLocks();
    
    // Check if already locked by someone else
    final existingLock = _umbrellaLocks.where((l) => l.umbrellaId == umbrellaId).firstOrNull;
    if (existingLock != null) {
      if (existingLock.userId != userId && !existingLock.isExpired) {
        return false; // Locked by someone else
      }
      // If expired or same user, we can overwrite/refresh
      _umbrellaLocks.remove(existingLock);
    }
    
    // Check if reserved/booked (existing logic inside availability check, but useful here too)
    // We assume caller checks isUmbrellaAvailable first, but let's be safe
    if (!isUmbrellaAvailable(umbrellaId, DateTime.now(), DateTime.now().add(const Duration(hours: 1)))) {
        // Technically strict check not possible without dates, but usually we lock for "now"
        // For simplicity allow lock, but booking will fail if unavailable.
    }

    _umbrellaLocks.add(UmbrellaLock(
      umbrellaId: umbrellaId,
      userId: userId,
      lockTime: DateTime.now(),
      expirationTime: DateTime.now().add(const Duration(minutes: 5)),
    ));
    
    notifyListeners();
    return true;
  }

  void unlockUmbrella(String umbrellaId) {
    _umbrellaLocks.removeWhere((l) => l.umbrellaId == umbrellaId);
    notifyListeners();
  }

  void cleanupExpiredLocks() {
    bool changed = false;
    _umbrellaLocks.removeWhere((lock) {
      if (lock.status == LockStatus.expired) {
        changed = true;
        return true;
      }
      return false;
    });
    if (changed) notifyListeners();
  }
  
  bool isUmbrellaLocked(String umbrellaId, String currentUserId) {
    cleanupExpiredLocks();
    final lock = _umbrellaLocks.where((l) => l.umbrellaId == umbrellaId).firstOrNull;
    if (lock == null) return false;
    return lock.userId != currentUserId;
  }
  
  bool isHeldBy(String umbrellaId, String userId) {
    cleanupExpiredLocks();
    final lock = _umbrellaLocks.where((l) => l.umbrellaId == umbrellaId).firstOrNull;
    return lock != null && lock.userId == userId;
  }
  
  List<UmbrellaLock> get allLocks => List.unmodifiable(_umbrellaLocks);
  
  DateTime? getLockExpiration(String umbrellaId) {
     final lock = _umbrellaLocks.where((l) => l.umbrellaId == umbrellaId).firstOrNull;
     return (lock != null && !lock.isExpired) ? lock.expirationTime : null;
  }

  // --- Initialization ---

  void _initializeMockData() {
    // 1. Zones (Rows/Pricing Tiers)
    _zones.addAll([
      BeachZone(id: 'z1', name: 'Prima Fila', color: Colors.blue.withOpacity(0.3), pricingType: PricingType.fixed, value: 0),
      BeachZone(id: 'z2', name: 'Seconda Fila', color: Colors.green.withOpacity(0.3), pricingType: PricingType.fixed, value: 0),
      BeachZone(id: 'z3', name: 'Standard', color: Colors.yellow.withOpacity(0.3), pricingType: PricingType.fixed, value: 0),
    ]);

    // 2. Packages
    _packages.addAll([
      ServicePackage(
        id: 'p1', 
        name: 'Base', 
        items: ['1 Ombrellone', '2 Lettini'], 
        description: 'Pacchetto standard per 2 persone',
        defaultBasePrice: 20.0,
      ),
      ServicePackage(
        id: 'p2', 
        name: 'Relax', 
        items: ['1 Ombrellone', '2 Lettini', '1 Regista'], 
        description: 'Per chi vuole più comodità',
        defaultBasePrice: 25.0,
      ),
      ServicePackage(
        id: 'p3', 
        name: 'King', 
        items: ['1 Ombrellone', '1 Letto King Size'], 
        description: 'Lusso e spazio extra',
        defaultBasePrice: 40.0,
      ),
    ]);
    
    // Financial Mock
    _financialSettings = FinancialSettings(
      companyName: 'Lido Bellissimo S.r.l.',
      iban: 'IT60X0542811101000000123456',
      companyAddress: 'Via Roma 1, Rimini',
      stripeEnabled: true,
      paypalEnabled: true,
    );

    // 3. Seasons
    final currentYear = DateTime.now().year;
    _seasons.addAll([
      Season(id: 's1', name: 'Bassa Stagione', startDate: DateTime(currentYear, 6, 1), endDate: DateTime(currentYear, 6, 30)),
      Season(id: 's2', name: 'Alta Stagione', startDate: DateTime(currentYear, 7, 1), endDate: DateTime(currentYear, 8, 31)),
      Season(id: 's3', name: 'Settembre', startDate: DateTime(currentYear, 9, 1), endDate: DateTime(currentYear, 9, 30)),
    ]);
    
    // 4. Price List (Matrix)
    // -- Bassa Stagione (June) --
    // Z1 (Prima Fila)
    _priceList.add(PriceListEntry(id: 'pl1', packageId: 'p1', zoneId: 'z1', seasonId: 's1', weekdayPrice: 25, fridayPrice: 30, saturdayPrice: 35, sundayPrice: 35));
    _priceList.add(PriceListEntry(id: 'pl2', packageId: 'p2', zoneId: 'z1', seasonId: 's1', weekdayPrice: 30, fridayPrice: 35, saturdayPrice: 40, sundayPrice: 40));
    // Z2 (Seconda Fila)
    _priceList.add(PriceListEntry(id: 'pl3', packageId: 'p1', zoneId: 'z2', seasonId: 's1', weekdayPrice: 20, fridayPrice: 25, saturdayPrice: 30, sundayPrice: 30));
    // Z3 (Standard)
    _priceList.add(PriceListEntry(id: 'pl4', packageId: 'p1', zoneId: 'z3', seasonId: 's1', weekdayPrice: 15, fridayPrice: 20, saturdayPrice: 25, sundayPrice: 25));

    // -- Alta Stagione (July/Aug) --
    _priceList.add(PriceListEntry(id: 'pl6', packageId: 'p1', zoneId: 'z1', seasonId: 's2', weekdayPrice: 40, fridayPrice: 50, saturdayPrice: 60, sundayPrice: 60));
    _priceList.add(PriceListEntry(id: 'pl7', packageId: 'p1', zoneId: 'z3', seasonId: 's2', weekdayPrice: 30, fridayPrice: 35, saturdayPrice: 45, sundayPrice: 45));
    
    // 4. Initialize Extra Equipment
    _extraEquipment.addAll([
      ExtraEquipment(
        id: 'chair_director',
        name: 'Sedia Regista',
        description: 'Comoda sedia pieghevole in legno',
        price: 5.0,
      ),
      ExtraEquipment(
        id: 'chair_deck',
        name: 'Sedia Sdraio',
        description: 'Sedia sdraio reclinabile',
        price: 8.0,
      ),
      ExtraEquipment(
        id: 'sunbed',
        name: 'Lettino',
        description: 'Lettino prendisole con materassino',
        price: 12.0,
      ),
    ]);
    
    // 5. Initialize Extra Services
    _extraServices.addAll([
      ExtraService(
        id: 'welcome_drink',
        name: 'Drink di Benvenuto',
        description: 'Cocktail analcolico di benvenuto',
        price: 8.0,
      ),
      ExtraService(
        id: 'aperitivo',
        name: 'Aperitivo al Tramonto',
        description: 'Aperitivo con vista mare al tramonto',
        price: 15.0,
      ),
      ExtraService(
        id: 'massage',
        name: 'Massaggio Relax',
        description: 'Massaggio rilassante di 30 minuti',
        price: 35.0,
      ),
    ]);

    // 6. Generate Map Elements
    // Add Sand
    _mapElements.add(MapElement(
      id: 'sand',
      type: MapElementType.sand,
      x: 0, y: 0.15,
      width: 1.0, height: 0.85,
      color: const Color(0xFFE6C288), // Sand color
    ));

    // Add Sea
    _mapElements.add(MapElement(
      id: 'sea',
      type: MapElementType.sea,
      x: 0, y: 0,
      width: 1.0, height: 0.15,
      color: Colors.blue.shade300,
      label: 'Mare',
    ));

    // Add Bar
    _mapElements.add(MapElement(
      id: 'bar',
      type: MapElementType.bar,
      x: 0.1, y: 0.2,
      width: 0.15, height: 0.1,
      color: Colors.brown,
      label: 'Bar',
    ));

    // Add Umbrellas (Grid)
    int rows = 5;
    int cols = 8;
    double startX = 0.1;
    double startY = 0.35;
    double spacingX = 0.1;
    double spacingY = 0.1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _mapElements.add(MapElement(
          id: 'umb_${r}_$c',
          type: MapElementType.umbrella,
          x: startX + (c * spacingX),
          y: startY + (r * spacingY),
          width: 0.05, height: 0.05,
          row: r + 1,
          number: c + 1,
          status: UmbrellaStatus.available,
          // Must match the seeded BeachZone / PriceListEntry ids ('z1'/'z2'/'z3')
          // — using different placeholder ids here would silently disconnect
          // every umbrella from the whole zone-based price list.
          zoneId: r == 0 ? 'z1' : (r > 3 ? 'z3' : 'z2'),
        ));
      }
    }
    
    // 5. Initialize Menu Data
    _initializeMenuData();

    // 7. Demo coupons
    _coupons.addAll([
      Coupon(code: 'ESTATE10', type: PricingType.percentage, value: 10),
      Coupon(code: 'BENVENUTO', type: PricingType.fixed, value: 5),
    ]);

    // 8. Restaurant floor plan (demo layout)
    _initializeRestaurantData();

    // 9. On-demand extra services marketplace (bar orders, timed rentals,
    // at-umbrella services) — reuses the same Season ids seeded above.
    _initializeExtraServicesMarketplace();
  }

  void _initializeExtraServicesMarketplace() {
    _extraServiceItems.addAll([
      ExtraServiceItem(
        id: 'bar_spritz',
        name: 'Spritz Aperitivo',
        description: 'Spritz classico servito all\'ombrellone',
        category: ExtraServiceCategory.bar,
        defaultPrice: 6.0,
      ),
      ExtraServiceItem(
        id: 'bar_welcome_drink',
        name: 'Drink di Benvenuto',
        description: 'Cocktail analcolico di benvenuto',
        category: ExtraServiceCategory.bar,
        defaultPrice: 5.0,
      ),
      ExtraServiceItem(
        id: 'rental_canoe_single',
        name: 'Canoa Singola',
        description: 'Noleggio canoa singola',
        category: ExtraServiceCategory.rental,
        durationMinutes: 60,
        capacity: 1,
        defaultPrice: 10.0,
      ),
      ExtraServiceItem(
        id: 'rental_canoe_double',
        name: 'Canoa Doppia',
        description: 'Noleggio canoa doppia',
        category: ExtraServiceCategory.rental,
        durationMinutes: 60,
        capacity: 2,
        defaultPrice: 16.0,
      ),
      ExtraServiceItem(
        id: 'rental_motorboat',
        name: 'Barca a Motore',
        description: 'Noleggio barca a motore, patente non richiesta entro 40 CV',
        category: ExtraServiceCategory.rental,
        durationMinutes: 60,
        defaultPrice: 45.0,
      ),
      ExtraServiceItem(
        id: 'court_beach_tennis',
        name: 'Campo Beach Tennis',
        description: 'Prenotazione campo beach tennis, racchette incluse',
        category: ExtraServiceCategory.court,
        durationMinutes: 60,
        defaultPrice: 18.0,
      ),
      ExtraServiceItem(
        id: 'service_massage',
        name: 'Massaggio Relax',
        description: 'Massaggio rilassante di 30 minuti, direttamente all\'ombrellone',
        category: ExtraServiceCategory.umbrellaService,
        durationMinutes: 30,
        defaultPrice: 35.0,
      ),
    ]);

    // Seasonal price overrides for the two most "period-sensitive" items —
    // the rest fall back to defaultPrice, demonstrating both paths.
    _extraPriceList.addAll([
      ExtraPriceListEntry(
          id: 'epl1',
          itemId: 'rental_canoe_single',
          seasonId: 's1',
          weekdayPrice: 8,
          fridayPrice: 10,
          saturdayPrice: 12,
          sundayPrice: 12),
      ExtraPriceListEntry(
          id: 'epl2',
          itemId: 'rental_canoe_single',
          seasonId: 's2',
          weekdayPrice: 10,
          fridayPrice: 13,
          saturdayPrice: 15,
          sundayPrice: 15),
      ExtraPriceListEntry(
          id: 'epl3',
          itemId: 'rental_canoe_double',
          seasonId: 's1',
          weekdayPrice: 13,
          fridayPrice: 16,
          saturdayPrice: 18,
          sundayPrice: 18),
      ExtraPriceListEntry(
          id: 'epl4',
          itemId: 'rental_canoe_double',
          seasonId: 's2',
          weekdayPrice: 16,
          fridayPrice: 20,
          saturdayPrice: 22,
          sundayPrice: 22),
      ExtraPriceListEntry(
          id: 'epl5',
          itemId: 'court_beach_tennis',
          seasonId: 's2',
          weekdayPrice: 18,
          fridayPrice: 22,
          saturdayPrice: 25,
          sundayPrice: 25),
    ]);
  }

  void _initializeRestaurantData() {
    const uuid = Uuid();

    _restaurantZones.addAll([
      RestaurantZone(id: 'rz1', name: 'Interno', colorValue: Colors.brown.shade200.toARGB32()),
      RestaurantZone(id: 'rz2', name: 'Terrazza', colorValue: Colors.orange.shade200.toARGB32()),
      RestaurantZone(id: 'rz3', name: 'Giardino', colorValue: Colors.green.shade200.toARGB32()),
    ]);

    // (x, y, seats, shape, zoneId) — rows map to Interno / Terrazza / Giardino.
    final layout = <(double, double, int, TableShape, String)>[
      (0.10, 0.15, 2, TableShape.round, 'rz1'),
      (0.25, 0.15, 2, TableShape.round, 'rz1'),
      (0.40, 0.15, 4, TableShape.square, 'rz1'),
      (0.55, 0.15, 4, TableShape.square, 'rz1'),
      (0.70, 0.15, 6, TableShape.rectangle, 'rz1'),
      (0.10, 0.40, 4, TableShape.square, 'rz2'),
      (0.25, 0.40, 4, TableShape.square, 'rz2'),
      (0.40, 0.40, 2, TableShape.round, 'rz2'),
      (0.55, 0.40, 8, TableShape.rectangle, 'rz2'),
      (0.10, 0.65, 6, TableShape.rectangle, 'rz3'),
      (0.35, 0.65, 4, TableShape.square, 'rz3'),
      (0.55, 0.65, 2, TableShape.round, 'rz3'),
    ];
    for (int i = 0; i < layout.length; i++) {
      final (x, y, seats, shape, zoneId) = layout[i];
      _restaurantTables.add(RestaurantTable(
        id: uuid.v4(),
        x: x,
        y: y,
        width: shape == TableShape.rectangle ? 0.14 : 0.09,
        height: 0.09,
        seats: seats,
        shape: shape,
        label: 'T${i + 1}',
        zoneId: zoneId,
      ));
    }
  }

  void _initializeMenuData() {
    // Categories
    _menuCategories.addAll([
      MenuCategory(id: 'antipasti', name: 'Antipasti', icon: Icons.tapas, sortOrder: 0),
      MenuCategory(id: 'pizze', name: 'Pizze', icon: Icons.local_pizza, sortOrder: 1),
      MenuCategory(id: 'primi', name: 'Primi', icon: Icons.ramen_dining, sortOrder: 2),
      MenuCategory(id: 'secondi', name: 'Secondi', icon: Icons.set_meal, sortOrder: 3),
      MenuCategory(id: 'dessert', name: 'Dessert', icon: Icons.icecream, sortOrder: 4),
      MenuCategory(id: 'drinks', name: 'Bevande', icon: Icons.local_drink, sortOrder: 5),
    ]);

    // Items
    _menuItems.addAll([
      // Antipasti
      MenuItem(
        id: 'antipasto_mare',
        categoryId: 'antipasti',
        name: 'Antipasto di Mare',
        description: 'Selezione di crudo e cotto del giorno, con crostini',
        price: 16.0,
        allergens: ['Crostacei', 'Pesce', 'Molluschi', 'Glutine'],
      ),
      MenuItem(
        id: 'bruschette',
        categoryId: 'antipasti',
        name: 'Bruschette Miste',
        description: 'Pomodoro fresco, olive e paté di olive, crema di carciofi',
        price: 8.0,
        allergens: ['Glutine'],
      ),
      // Pizze
      MenuItem(
        id: 'pizza_margherita',
        categoryId: 'pizze',
        name: 'Margherita',
        description: 'Pomodoro, mozzarella, basilico',
        price: 7.0,
        allergens: ['Glutine', 'Latte'],
      ),
      MenuItem(
        id: 'pizza_marinara',
        categoryId: 'pizze',
        name: 'Marinara',
        description: 'Pomodoro, aglio, origano',
        price: 6.0,
        allergens: ['Glutine'],
      ),
      // Primi
      MenuItem(
        id: 'risotto_pescatore',
        categoryId: 'primi',
        name: 'Risotto alla Pescatora',
        description: 'Riso Carnaroli, misto di pesce e crostacei del giorno',
        price: 18.0,
        allergens: ['Crostacei', 'Pesce', 'Molluschi'],
        minOrderQuantity: 2,
        minOrderNote: 'Minimo per 2 persone',
      ),
      MenuItem(
        id: 'spaghetti_vongole',
        categoryId: 'primi',
        name: 'Spaghetti alle Vongole',
        description: 'Vongole veraci, aglio, olio e prezzemolo',
        price: 15.0,
        allergens: ['Glutine', 'Molluschi'],
      ),
      // Secondi
      MenuItem(
        id: 'grigliata_pesce',
        categoryId: 'secondi',
        name: 'Grigliata Mista di Pesce',
        description: 'Pesce e crostacei alla griglia con contorno',
        price: 24.0,
        allergens: ['Pesce', 'Crostacei'],
      ),
      MenuItem(
        id: 'tagliata_manzo',
        categoryId: 'secondi',
        name: 'Tagliata di Manzo',
        description: 'Rucola, grana e pomodorini',
        price: 20.0,
        allergens: ['Latte'],
      ),
      // Dessert
      MenuItem(
        id: 'tiramisu',
        categoryId: 'dessert',
        name: 'Tiramisù della Casa',
        description: 'Ricetta tradizionale fatta in casa',
        price: 6.0,
        allergens: ['Glutine', 'Uova', 'Latte'],
      ),
      MenuItem(
        id: 'icecream_cone',
        categoryId: 'dessert',
        name: 'Cono Gelato',
        description: 'Cioccolato e panna',
        price: 2.5,
        allergens: ['Latte'],
      ),
      // Bevande
      MenuItem(id: 'coke', categoryId: 'drinks', name: 'Coca Cola', price: 3.0, description: 'Lattina 33cl'),
      MenuItem(id: 'water', categoryId: 'drinks', name: 'Acqua', price: 1.5, description: 'Bottiglia 50cl'),
    ]);
  }

  // --- Map Element Methods ---
  
  void addMapElement(MapElement element) {
    _mapElements.add(element);
    notifyListeners();
  }

  void updateMapElement(MapElement element) {
    final index = _mapElements.indexWhere((e) => e.id == element.id);
    if (index != -1) {
      _mapElements[index] = element;
      notifyListeners();
    }
  }

  void removeMapElement(String id) {
    _mapElements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- Booking Methods ---

  // Check if umbrella is available for given date range
  bool isUmbrellaAvailable(String umbrellaId, DateTime startDate, DateTime endDate) {
    // 1. Check Locks
    cleanupExpiredLocks();
    final lock = _umbrellaLocks.where((l) => l.umbrellaId == umbrellaId).firstOrNull;
    if (lock != null) {
      // Locked by someone else?
      if (lock.userId != (authService.currentUser?.id ?? 'guest')) {
          return false;
      }
    }

    // 2. Check Bookings
    for (var booking in _bookings) {
      if (booking.umbrellaId == umbrellaId) {
        // Check if dates overlap
        // Overlap occurs if (StartA <= EndB) and (EndA >= StartB)
        if (startDate.isBefore(booking.endDate.add(const Duration(days: 1))) && 
            endDate.isAfter(booking.startDate.subtract(const Duration(days: 1)))) {
          return false; // Dates overlap, not available
        }
      }
    }
    return true; // No conflicts, available
  }

  // Record a transaction
  void recordTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }
  
  /// Adds a manually-created booking (e.g. operator walk-in entry).
  /// Returns null on success, or an error message if the umbrella is
  /// already booked for an overlapping date in the requested range.
  String? addBooking(Booking booking) {
    for (final b in _bookings) {
      if (b.umbrellaId == booking.umbrellaId &&
          b.status != BookingStatus.cancelled) {
        if (booking.startDate
                .isBefore(b.endDate.add(const Duration(days: 1))) &&
            booking.endDate
                .isAfter(b.startDate.subtract(const Duration(days: 1)))) {
          return 'Ombrellone ${umbrellaLabel(booking.umbrellaId)} già occupato nel periodo selezionato.';
        }
      }
    }
    _bookings.add(booking);
    notifyListeners();
    return null;
  }

  /// Updates an existing booking. If [umbrellaId] or the date range changed,
  /// re-validates against overlapping bookings on the (possibly new)
  /// umbrella. Returns null on success, or an error message on conflict.
  String? updateBooking(Booking booking) {
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) return 'Prenotazione non trovata';

    for (final b in _bookings) {
      if (b.id == booking.id) continue;
      if (b.umbrellaId == booking.umbrellaId &&
          b.status != BookingStatus.cancelled) {
        if (booking.startDate
                .isBefore(b.endDate.add(const Duration(days: 1))) &&
            booking.endDate
                .isAfter(b.startDate.subtract(const Duration(days: 1)))) {
          return 'Ombrellone ${umbrellaLabel(booking.umbrellaId)} già occupato nel periodo selezionato.';
        }
      }
    }

    _bookings[index] = booking;
    notifyListeners();
    return null;
  }
  
  void deleteBooking(String bookingId) {
    _bookings.removeWhere((b) => b.id == bookingId);
    notifyListeners();
  }

  // --- Menu Methods ---

  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = order.copyWith(
        status: status,
        completedAt: (status == OrderStatus.served || status == OrderStatus.cancelled)
            ? DateTime.now()
            : order.completedAt,
      );
      notifyListeners();
    }
  }

  // Live orders that still need attention (not served/cancelled)
  List<Order> get activeOrders => _orders
      .where((o) => o.status != OrderStatus.served && o.status != OrderStatus.cancelled)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // Place an order from a customer, tied to an umbrella label
  Order placeOrder({
    String? umbrellaId,
    String? umbrellaLabel,
    String? customerName,
    required List<OrderItem> items,
    String? notes,
  }) {
    final order = Order(
      id: const Uuid().v4(),
      umbrellaId: umbrellaId,
      umbrellaLabel: umbrellaLabel,
      customerName: customerName,
      items: items,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
    );
    addOrder(order);
    _pushNotification(
      title: 'Nuovo ordine bar',
      body: '${umbrellaLabel != null ? 'Ombrellone $umbrellaLabel' : 'Bancone'} • ${items.length} articoli • €${order.totalPrice.toStringAsFixed(2)}',
      type: AppNotificationType.order,
      refId: order.id,
    );
    return order;
  }

  double get todayOrdersRevenue {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.status != OrderStatus.cancelled &&
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .fold(0.0, (sum, o) => sum + o.totalPrice);
  }

  // --- Menu Category CRUD ---
  void addMenuCategory(MenuCategory category) {
    _menuCategories.add(category);
    notifyListeners();
  }

  void updateMenuCategory(MenuCategory category) {
    final index = _menuCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _menuCategories[index] = category;
      notifyListeners();
    }
  }

  void deleteMenuCategory(String id) {
    _menuCategories.removeWhere((c) => c.id == id);
    _menuItems.removeWhere((i) => i.categoryId == id);
    notifyListeners();
  }

  // --- Menu Item CRUD ---
  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    notifyListeners();
  }

  void updateMenuItem(MenuItem item) {
    final index = _menuItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _menuItems[index] = item;
      notifyListeners();
    }
  }

  void deleteMenuItem(String id) {
    _menuItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }
  // --- Zone Methods ---

  void addZone(BeachZone zone) {
    _zones.add(zone);
    notifyListeners();
  }

  void updateZone(BeachZone zone) {
    final index = _zones.indexWhere((z) => z.id == zone.id);
    if (index != -1) {
      _zones[index] = zone;
      notifyListeners();
    }
  }

  void deleteZone(String id) {
    _zones.removeWhere((z) => z.id == id);
    // Also clear zoneId from umbrellas that were in this zone
    for (var element in _mapElements) {
      if (element.zoneId == id) {
        element.zoneId = null;
      }
    }
    notifyListeners();
  }

  void assignUmbrellasToZone(List<String> umbrellaIds, String zoneId) {
    bool changed = false;
    for (var element in _mapElements) {
      if (umbrellaIds.contains(element.id)) {
        element.zoneId = zoneId;
        changed = true;
      } else if (element.zoneId == zoneId && !umbrellaIds.contains(element.id)) {
        // Optional: Remove from zone if not in the new list? 
        // For now, let's assume the list contains ALL umbrellas that should be in the zone.
        // Or maybe we just update the ones passed.
        // Let's stick to: update the ones passed. If we want to clear others, we'd need a different logic.
        // Actually, usually "assign to zone" implies these specific ones belong to it.
        // But if I select a row, I expect that row to be added.
        // Let's implement it as: Set zoneId for these umbrellas.
      }
    }
    
    // Better approach for "Visual Editor": 
    // The editor will likely pass the list of ALL umbrellas that currently belong to this zone.
    // So we should probably clear the zoneId for any umbrella that currently has this zoneId but is NOT in the list,
    // AND set the zoneId for any umbrella in the list.
    
    for (var element in _mapElements) {
      if (element.zoneId == zoneId && !umbrellaIds.contains(element.id)) {
        element.zoneId = null; // Remove from zone
        changed = true;
      }
      if (umbrellaIds.contains(element.id) && element.zoneId != zoneId) {
        element.zoneId = zoneId; // Add to zone
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
  
  // --- Package Methods ---

  void addPackage(ServicePackage package) {
    _packages.add(package);
    notifyListeners();
  }

  void updatePackage(ServicePackage package) {
    final index = _packages.indexWhere((p) => p.id == package.id);
    if (index != -1) {
      _packages[index] = package;
      notifyListeners();
    }
  }

  void deletePackage(String id) {
    _packages.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // --- Price Rule Methods (legacy/compatibility) ---

  void addPriceRule(PriceRule rule) {
    _priceRules.add(rule);
    notifyListeners();
  }

  void updatePriceRule(PriceRule rule) {
    final index = _priceRules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _priceRules[index] = rule;
      notifyListeners();
    }
  }

  void deletePriceRule(String id) {
    _priceRules.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // --- Season Methods ---

  /// Seasons must not overlap — activeSeasonOn() only ever resolves to one
  /// season per date, so an overlap would silently hide one season's price
  /// list on the shared days. Re-validated here (not just in the pricing
  /// screen's dialog) so any future caller gets the same guarantee.
  String? _seasonOverlapError(Season season) {
    final overlapping = _seasons.where((s) =>
        s.id != season.id &&
        season.startDate.isBefore(s.endDate.add(const Duration(days: 1))) &&
        season.endDate.isAfter(s.startDate.subtract(const Duration(days: 1))));
    if (overlapping.isEmpty) return null;
    return 'Il periodo si sovrappone a: ${overlapping.map((s) => s.name).join(', ')}';
  }

  String? addSeason(Season season) {
    final error = _seasonOverlapError(season);
    if (error != null) return error;
    _seasons.add(season);
    notifyListeners();
    return null;
  }

  String? updateSeason(Season season) {
    final error = _seasonOverlapError(season);
    if (error != null) return error;
    final index = _seasons.indexWhere((s) => s.id == season.id);
    if (index != -1) {
      _seasons[index] = season;
      notifyListeners();
    }
    return null;
  }

  void deleteSeason(String id) {
    _seasons.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // --- Price List Entry Methods ---

  void addPriceListEntry(PriceListEntry entry) {
    _priceList.add(entry);
    notifyListeners();
  }

  void updatePriceListEntry(PriceListEntry entry) {
    final index = _priceList.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _priceList[index] = entry;
    } else {
      _priceList.add(entry);
    }
    notifyListeners();
  }

  void deletePriceListEntry(String id) {
    _priceList.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// The season [date] falls into, if any.
  Season? activeSeasonOn(DateTime date) {
    for (final s in _seasons) {
      if (!date.isBefore(s.startDate) && !date.isAfter(s.endDate)) return s;
    }
    return null;
  }

  /// Packages actually on sale for [umbrellaId], derived from its zone's
  /// price list entries (any season). Falls back to every package if the
  /// umbrella has no zone or no zone-specific price list exists.
  List<ServicePackage> packagesForUmbrella(String umbrellaId) {
    final umbrella = _mapElements.where((e) => e.id == umbrellaId).firstOrNull;
    final zoneId = umbrella?.zoneId;
    if (zoneId == null) return _packages;

    final packageIds = _priceList
        .where((e) => e.zoneId == zoneId)
        .map((e) => e.packageId)
        .toSet();
    if (packageIds.isEmpty) return _packages;

    return _packages.where((p) => packageIds.contains(p.id)).toList();
  }

  /// Price of [packageId] on [umbrellaId] for [date]: looks up the zone's
  /// price list entry for the active season, falling back to the package's
  /// flat default price when no specific entry is configured.
  double priceForPackageOnUmbrella(
      String packageId, String umbrellaId, DateTime date) {
    final umbrella = _mapElements.where((e) => e.id == umbrellaId).firstOrNull;
    final package = _packages.where((p) => p.id == packageId).firstOrNull;
    final fallback = package?.defaultBasePrice ?? 0.0;
    if (umbrella?.zoneId == null) return fallback;

    final season = activeSeasonOn(date);
    if (season == null) return fallback;

    final entry = _priceList
        .where((e) =>
            e.packageId == packageId &&
            e.zoneId == umbrella!.zoneId &&
            e.seasonId == season.id)
        .firstOrNull;
    return entry?.getPriceForDate(date) ?? fallback;
  }

  // --- Extra Equipment Methods ---

  // Unfiltered list for admin management (the public `extraEquipment` getter
  // hides unavailable items for the customer-facing booking flow, which would
  // make a disabled item impossible for an admin to find and re-enable).
  List<ExtraEquipment> get allExtraEquipment => List.unmodifiable(_extraEquipment);

  void addExtraEquipment(ExtraEquipment equipment) {
    _extraEquipment.add(equipment);
    notifyListeners();
  }

  void updateExtraEquipment(ExtraEquipment equipment) {
    final index = _extraEquipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _extraEquipment[index] = equipment;
      notifyListeners();
    }
  }

  void deleteExtraEquipment(String id) {
    _extraEquipment.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- Extra Service Methods ---

  List<ExtraService> get allExtraServices => List.unmodifiable(_extraServices);

  void addExtraService(ExtraService service) {
    _extraServices.add(service);
    notifyListeners();
  }

  void updateExtraService(ExtraService service) {
    final index = _extraServices.indexWhere((s) => s.id == service.id);
    if (index != -1) {
      _extraServices[index] = service;
      notifyListeners();
    }
  }

  void deleteExtraService(String id) {
    _extraServices.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void unlockMultipleUmbrellas(List<String> umbrellaIds) {
    for (var id in umbrellaIds) {
      unlockUmbrella(id);
    }
  }

  // Create multiple bookings and record transactions
  /// Creates one booking per umbrella, each priced according to ITS OWN
  /// zone/season/weekday price list — not a single shared average. Shared
  /// costs (extras, booking fee, VAT, payment fee, discount, deposit) are
  /// pooled and split proportionally to each umbrella's own package price
  /// share (booking fee/VAT are percentage-based so computing them directly
  /// on each umbrella's own subtotal is naturally proportional; only the
  /// flat pool amounts — extras/discount/paymentFee/deposit — need an
  /// explicit ratio split).
  Map<String, dynamic> createMultipleBookingsAndTransactions({
    required Map<String, double> pricePerUmbrella,
    required String packageId,
    required String customerName,
    required DateTime startDate,
    required DateTime endDate,
    required List<BookingExtra> extras,
    required double extrasTotal,
    required double bookingFeePercentage,
    required double vatPercentage,
    required double paymentFeeTotal,
    required PaymentProvider provider,
    required String paymentReference,
    double discountTotal = 0,
    String? couponCode,
    double depositTotal = 0,
  }) {
    final umbrellaIds = pricePerUmbrella.keys.toList();
    final packageSubtotal = pricePerUmbrella.values.fold(0.0, (a, b) => a + b);

    // 1. Validate all umbrellas exist and are available (checking locks for CURRENT user)
    final currentUserId = authService.currentUser?.id ?? 'guest';

    for (final umbrellaId in umbrellaIds) {
      // Check if locked by SOMEONE ELSE
      if (isUmbrellaLocked(umbrellaId, currentUserId)) {
         return {
          'success': false,
          'message': 'Uno o più ombrelloni non sono più disponibili.',
          'bookingIds': null,
        };
      }
      
      // Check bookings overlap
      // We manually check bookings ignoring locks since we might hold the lock
      for (var booking in _bookings) {
          if (booking.umbrellaId == umbrellaId) {
            if (startDate.isBefore(booking.endDate.add(const Duration(days: 1))) && 
                endDate.isAfter(booking.startDate.subtract(const Duration(days: 1)))) {
              return {
                  'success': false,
                  'message': 'Ombrellone occupato per le date selezionate.',
                  'bookingIds': null,
              };
            }
          }
      }
    }

    // 2. Create bookings and transactions — each priced using its own
    // umbrella's package price, with pooled costs (extras/discount/payment
    // fee/deposit) split proportionally to that share.
    List<String> createdBookingIds = [];
    double grandTotal = 0;
    try {
      for (final umbrellaId in umbrellaIds) {
        unlockUmbrella(umbrellaId); // Release lock as we are confirming

        final ownPackagePrice = pricePerUmbrella[umbrellaId]!;
        final shareRatio =
            packageSubtotal > 0 ? ownPackagePrice / packageSubtotal : 1 / umbrellaIds.length;
        final ownExtrasShare = extrasTotal * shareRatio;
        final ownSubtotal = ownPackagePrice + ownExtrasShare;
        final ownBookingFee = ownSubtotal * (bookingFeePercentage / 100);
        final ownVat = ownSubtotal * (vatPercentage / 100);
        final ownPaymentFee = paymentFeeTotal * shareRatio;
        final ownDiscount = discountTotal * shareRatio;
        final ownTotalRaw = ownSubtotal - ownDiscount + ownBookingFee + ownVat + ownPaymentFee;
        final ownTotal = ownTotalRaw < 0 ? 0.0 : ownTotalRaw;
        final ownDeposit = depositTotal * shareRatio;

        final bookingId = const Uuid().v4();
        final isDeposit = ownDeposit > 0 && ownDeposit < ownTotal;
        // Amount actually collected now: deposit if partial, else full total (unless manual)
        final double chargedNow = isDeposit ? ownDeposit : ownTotal;
        // A booking is fully paid only if the full amount was collected online.
        final fullyPaid = provider != PaymentProvider.manual && !isDeposit;

        final booking = Booking(
          id: bookingId,
          umbrellaId: umbrellaId,
          userId: currentUserId,
          startDate: startDate,
          endDate: endDate,
          status: BookingStatus.confirmed,
          customerName: customerName,
          packageId: packageId,
          totalPrice: ownTotal,
          isPaid: fullyPaid,
          extras: extras,
          subtotal: ownSubtotal,
          bookingFee: ownBookingFee,
          vat: ownVat,
          paymentFee: ownPaymentFee,
          discountAmount: ownDiscount,
          couponCode: couponCode,
          deposit: isDeposit ? ownDeposit : (fullyPaid ? ownTotal : 0.0),
        );

        _bookings.add(booking);
        createdBookingIds.add(bookingId);
        grandTotal += ownTotal;

        // Record Transaction for the amount collected now
        recordTransaction(Transaction(
          id: const Uuid().v4(),
          bookingId: bookingId,
          amount: chargedNow,
          date: DateTime.now(),
          provider: provider,
          status: provider == PaymentProvider.manual ? 'pending' : 'completed',
          externalReference: paymentReference,
        ));
      }

      _pushNotification(
        title: 'Nuova prenotazione',
        body:
            '$customerName • ${umbrellaIds.length} ombrellone/i • €${grandTotal.toStringAsFixed(2)}',
        type: AppNotificationType.booking,
        refId: createdBookingIds.isNotEmpty ? createdBookingIds.first : null,
      );

      notifyListeners();
      
      return {
        'success': true,
        'message': 'Pagamento riuscito e prenotazioni confermate!',
        'bookingIds': createdBookingIds,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante la prenotazione multipla: ${e.toString()}',
        'bookingIds': null,
      };
    }
  }

  // --- Daily map status / Absence / Sharing ---

  List<BookingShare> get shares => List.unmodifiable(_shares);

  double serviceCreditFor(String userId) => _serviceCredits[userId] ?? 0.0;

  /// The active (non-cancelled) booking occupying [umbrellaId] on [day], if any.
  Booking? bookingForUmbrellaOn(String umbrellaId, DateTime day) {
    for (final b in _bookings) {
      if (b.umbrellaId == umbrellaId && _bookingCoversDate(b, day)) {
        return b;
      }
    }
    return null;
  }

  UmbrellaDayStatus umbrellaDayStatus(String umbrellaId, DateTime day) {
    final b = bookingForUmbrellaOn(umbrellaId, day);
    if (b == null) return UmbrellaDayStatus.free;
    if (b.isAbsentOn(day)) return UmbrellaDayStatus.absentResellable;
    if (b.checkedIn && _isSameDay(day, DateTime.now())) {
      return UmbrellaDayStatus.checkedIn;
    }
    return b.channel == BookingChannel.onSite
        ? UmbrellaDayStatus.bookedOnSite
        : UmbrellaDayStatus.bookedOnline;
  }

  double _perDayPrice(Booking b) {
    final nights = b.endDate.difference(b.startDate).inDays + 1;
    return nights <= 0 ? b.totalPrice : b.totalPrice / nights;
  }

  /// All active (non-cancelled) bookings on [umbrellaId] that intersect
  /// [rangeStart]..[rangeEnd] (inclusive). Used by the range-mode beach map.
  List<Booking> bookingsForUmbrellaInRange(
      String umbrellaId, DateTime rangeStart, DateTime rangeEnd) {
    return _bookings
        .where((b) =>
            b.umbrellaId == umbrellaId &&
            b.status != BookingStatus.cancelled &&
            rangeStart.isBefore(b.endDate.add(const Duration(days: 1))) &&
            rangeEnd.isAfter(b.startDate.subtract(const Duration(days: 1))))
        .toList();
  }

  /// Adds an equipment/service extra to an existing booking, optionally
  /// restricted to specific days of the stay (e.g. a sunbed added for just
  /// 2 of the 7 booked days). Recomputes subtotal and total accordingly.
  /// Returns null on success, or an error message.
  String? addExtraToBooking({
    required String bookingId,
    required String id,
    required String name,
    required double price,
    required bool isService,
    int quantity = 1,
    List<DateTime>? forDates,
  }) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return 'Prenotazione non trovata';
    final booking = _bookings[index];

    final days = (forDates == null || forDates.isEmpty)
        ? null
        : forDates
            .where((d) =>
                !d.isBefore(booking.startDate) && !d.isAfter(booking.endDate))
            .toList();
    if (forDates != null && forDates.isNotEmpty && (days == null || days.isEmpty)) {
      return 'Le date selezionate non rientrano nel periodo della prenotazione';
    }

    final unitsOfTime = days?.length ?? booking.durationInDays;
    final cost = price * quantity * unitsOfTime;

    final extra = BookingExtra(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      isService: isService,
      forDates: days,
    );

    _bookings[index] = booking.copyWith(
      extras: [...booking.extras, extra],
      subtotal: booking.subtotal + cost,
      totalPrice: booking.totalPrice + cost,
    );
    notifyListeners();
    return null;
  }

  /// Removes a previously added extra from a booking and refunds its cost.
  void removeExtraFromBooking(String bookingId, int extraIndex) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    final booking = _bookings[index];
    if (extraIndex < 0 || extraIndex >= booking.extras.length) return;

    final extra = booking.extras[extraIndex];
    final unitsOfTime = extra.forDates?.length ?? booking.durationInDays;
    final cost = extra.price * extra.quantity * unitsOfTime;

    final newExtras = [...booking.extras]..removeAt(extraIndex);
    _bookings[index] = booking.copyWith(
      extras: newExtras,
      subtotal: booking.subtotal - cost,
      totalPrice: booking.totalPrice - cost,
    );
    notifyListeners();
  }

  /// Owner flags an absence for [day]. If notified at least 24h before the day
  /// starts, the owner earns a 30% service credit for that day, and the
  /// operator is notified the position can be resold.
  /// Returns the granted credit (0 if none).
  double markAbsence(String bookingId, DateTime day) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return 0;
    final b = _bookings[index];
    final target = DateTime(day.year, day.month, day.day);
    if (b.isAbsentOn(target)) return 0;

    final newDates = List<DateTime>.from(b.absentDates)..add(target);
    _bookings[index] = b.copyWith(absentDates: newDates);

    double credit = 0;
    final hoursBefore = target.difference(DateTime.now()).inHours;
    if (hoursBefore >= 24) {
      credit = _perDayPrice(b) * 0.30;
      _serviceCredits[b.userId] = (_serviceCredits[b.userId] ?? 0) + credit;
    }

    _pushNotification(
      title: 'Postazione rivendibile',
      body:
          'Ombrellone ${umbrellaLabel(b.umbrellaId)} libero il ${_formatDate(target)} (assenza di ${b.customerName})',
      type: AppNotificationType.booking,
      refId: bookingId,
    );
    notifyListeners();
    return credit;
  }

  void cancelAbsence(String bookingId, DateTime day) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    final b = _bookings[index];
    final newDates = b.absentDates
        .where((d) => !(d.year == day.year && d.month == day.month && d.day == day.day))
        .toList();
    _bookings[index] = b.copyWith(absentDates: newDates);
    notifyListeners();
  }

  /// Owner shares (part of) a booking with another user for [startDate]..[endDate].
  /// Returns the unique share code to hand over.
  String shareBooking(String bookingId, DateTime startDate, DateTime endDate) {
    final b = _bookings.firstWhere((b) => b.id == bookingId);
    // Short human-friendly code
    final code = 'SH-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    _shares.add(BookingShare(
      code: code,
      bookingId: bookingId,
      ownerUserId: b.userId,
      ownerName: b.customerName,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
    ));
    final index = _bookings.indexWhere((x) => x.id == bookingId);
    _bookings[index] = b.copyWith(shareCode: code);
    notifyListeners();
    return code;
  }

  /// Another user imports a share code. Creates a recipient-side booking copy
  /// for the shared window. Returns null on success or an error message.
  String? importShare(String code, String userId, String userName) {
    final share = _shares
        .where((s) => s.code.toUpperCase() == code.trim().toUpperCase())
        .firstOrNull;
    if (share == null) return 'Codice sharing non valido';
    if (share.isClaimed) return 'Questo codice è già stato utilizzato';
    if (share.ownerUserId == userId) {
      return 'Non puoi importare una tua stessa prenotazione';
    }

    final original = _bookings.where((b) => b.id == share.bookingId).firstOrNull;
    if (original == null) return 'Prenotazione originale non trovata';

    share.claimedByUserId = userId;
    share.claimedAt = DateTime.now();

    _bookings.add(Booking(
      id: const Uuid().v4(),
      umbrellaId: original.umbrellaId,
      userId: userId,
      customerName: userName,
      startDate: share.startDate,
      endDate: share.endDate,
      status: BookingStatus.confirmed,
      totalPrice: 0,
      isPaid: true,
      packageId: original.packageId,
      channel: BookingChannel.online,
      sharedFromBookingId: original.id,
    ));

    _pushNotification(
      title: 'Sharing prenotazione',
      body:
          '$userName ha ricevuto la postazione ${umbrellaLabel(original.umbrellaId)} da ${share.ownerName}',
      type: AppNotificationType.booking,
      refId: share.bookingId,
    );
    notifyListeners();
    return null;
  }

  // --- Analytics / Statistics ---

  bool _bookingCoversDate(Booking b, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
    final end = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
    return !d.isBefore(start) &&
        !d.isAfter(end) &&
        b.status != BookingStatus.cancelled;
  }

  /// Umbrellas booked on [day] (default: today).
  int occupiedUmbrellasOn([DateTime? day]) {
    final target = day ?? DateTime.now();
    final ids = _bookings
        .where((b) => _bookingCoversDate(b, target))
        .map((b) => b.umbrellaId)
        .toSet();
    return ids.length;
  }

  /// Occupancy ratio 0..1 for [day].
  double occupancyRate([DateTime? day]) {
    final total = umbrellas.length;
    if (total == 0) return 0;
    return occupiedUmbrellasOn(day) / total;
  }

  List<Booking> arrivalsOn([DateTime? day]) {
    final target = day ?? DateTime.now();
    return _bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            _isSameDay(b.startDate, target))
        .toList();
  }

  List<Booking> departuresOn([DateTime? day]) {
    final target = day ?? DateTime.now();
    return _bookings
        .where((b) =>
            b.status != BookingStatus.cancelled &&
            _isSameDay(b.endDate, target))
        .toList();
  }

  /// Revenue from paid transactions within [start]..[end] (inclusive).
  double revenueForPeriod(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.status == 'completed' &&
            !t.date.isBefore(s) &&
            !t.date.isAfter(e))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get revenueToday {
    final now = DateTime.now();
    return revenueForPeriod(now, now);
  }

  double get revenueThisMonth {
    final now = DateTime.now();
    return revenueForPeriod(DateTime(now.year, now.month, 1), now);
  }

  /// Revenue per day for the last [days] days (oldest first).
  List<MapEntry<DateTime, double>> revenueLastDays(int days) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, double>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result.add(MapEntry(day, revenueForPeriod(day, day)));
    }
    return result;
  }

  /// Occupancy per zone for [day]: zoneId -> (occupied, total).
  Map<String, (int occupied, int total)> occupancyByZone([DateTime? day]) {
    final target = day ?? DateTime.now();
    final occupiedIds = _bookings
        .where((b) => _bookingCoversDate(b, target))
        .map((b) => b.umbrellaId)
        .toSet();
    final result = <String, (int, int)>{};
    for (final u in umbrellas) {
      final key = u.zoneId ?? 'unassigned';
      final current = result[key] ?? (0, 0);
      result[key] = (
        current.$1 + (occupiedIds.contains(u.id) ? 1 : 0),
        current.$2 + 1,
      );
    }
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // --- QR Code Methods ---
  CheckInResult validateCheckIn(String bookingId) {
    // Find booking
    final booking = _bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => Booking(
        id: '',
        umbrellaId: '',
        userId: '',
        customerName: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        totalPrice: 0,
      ),
    );
    
    if (booking.id.isEmpty) {
      return CheckInResult(
        isValid: false,
        status: CheckInStatus.notFound,
        message: 'Prenotazione non trovata',
      );
    }
    
    // Check date validity
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
    final bookingEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
    
    if (today.isAfter(bookingEnd)) {
      return CheckInResult(
        isValid: false,
        status: CheckInStatus.expired,
        message: 'Prenotazione scaduta (${_formatDate(booking.endDate)})',
        booking: booking,
      );
    }
    
    if (today.isBefore(bookingStart)) {
      return CheckInResult(
        isValid: false,
        status: CheckInStatus.future,
        message: 'Prenotazione futura (Inizia il ${_formatDate(booking.startDate)})',
        booking: booking,
      );
    }
    
    // Valid check-in
    return CheckInResult(
      isValid: true,
      status: CheckInStatus.valid,
      message: 'Check-in valido!',
      booking: booking,
    );
  }
  
  /// Validate a check-OUT against an existing booking (must be checked-in first).
  CheckInResult validateCheckOut(String bookingId) {
    final booking = _bookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) {
      return CheckInResult(
        isValid: false,
        status: CheckInStatus.notFound,
        message: 'Prenotazione non trovata',
      );
    }
    if (booking.checkedOut) {
      return CheckInResult(
        isValid: false,
        status: CheckInStatus.expired,
        message: 'Check-out già effettuato',
        booking: booking,
      );
    }
    return CheckInResult(
      isValid: true,
      status: CheckInStatus.valid,
      message: 'Check-out valido!',
      booking: booking,
    );
  }

  void performCheckIn(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index].copyWith(checkedIn: true);
    _pushNotification(
      title: 'Check-in effettuato',
      body:
          '${_bookings[index].customerName} • Ombrellone ${umbrellaLabel(_bookings[index].umbrellaId)}',
      type: AppNotificationType.checkIn,
      refId: bookingId,
    );
    notifyListeners();
  }

  void performCheckOut(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _bookings[index] = _bookings[index]
        .copyWith(checkedOut: true, status: BookingStatus.completed);
    _pushNotification(
      title: 'Check-out effettuato',
      body:
          '${_bookings[index].customerName} • Ombrellone ${umbrellaLabel(_bookings[index].umbrellaId)}',
      type: AppNotificationType.checkIn,
      refId: bookingId,
    );
    notifyListeners();
  }

  /// Move a booking to a different umbrella (planner reposition / resale).
  /// Returns null on success, or an error message.
  String? moveBooking(String bookingId, String newUmbrellaId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return 'Prenotazione non trovata';
    final booking = _bookings[index];
    if (booking.umbrellaId == newUmbrellaId) return null;

    // Ensure target umbrella exists
    if (_mapElements.where((e) => e.id == newUmbrellaId).isEmpty) {
      return 'Ombrellone di destinazione non valido';
    }

    // Ensure no overlap on the target umbrella (ignoring this booking)
    for (final b in _bookings) {
      if (b.id == booking.id) continue;
      if (b.umbrellaId == newUmbrellaId &&
          b.status != BookingStatus.cancelled) {
        if (booking.startDate
                .isBefore(b.endDate.add(const Duration(days: 1))) &&
            booking.endDate
                .isAfter(b.startDate.subtract(const Duration(days: 1)))) {
          return 'Ombrellone ${umbrellaLabel(newUmbrellaId)} occupato nel periodo';
        }
      }
    }

    _bookings[index] = booking.copyWith(umbrellaId: newUmbrellaId);
    _pushNotification(
      title: 'Prenotazione spostata',
      body:
          '${booking.customerName}: ${umbrellaLabel(booking.umbrellaId)} → ${umbrellaLabel(newUmbrellaId)}',
      type: AppNotificationType.booking,
      refId: bookingId,
    );
    notifyListeners();
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get bookings for a specific user
  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }

  // --- Restaurant Module ---

  List<RestaurantTable> get restaurantTables => List.unmodifiable(_restaurantTables);
  List<TableBooking> get tableBookings => List.unmodifiable(_tableBookings);
  List<RestaurantZone> get restaurantZones => List.unmodifiable(_restaurantZones);

  String restaurantZoneName(String? zoneId) {
    if (zoneId == null) return 'Senza zona';
    return _restaurantZones.where((z) => z.id == zoneId).firstOrNull?.name ?? 'Senza zona';
  }

  void addRestaurantZone(RestaurantZone zone) {
    _restaurantZones.add(zone);
    notifyListeners();
  }

  void updateRestaurantZone(RestaurantZone zone) {
    final index = _restaurantZones.indexWhere((z) => z.id == zone.id);
    if (index != -1) {
      _restaurantZones[index] = zone;
      notifyListeners();
    }
  }

  void deleteRestaurantZone(String id) {
    _restaurantZones.removeWhere((z) => z.id == id);
    for (final t in _restaurantTables) {
      if (t.zoneId == id) t.zoneId = null;
    }
    notifyListeners();
  }

  String restaurantTableLabel(String tableId) {
    final t = _restaurantTables.where((t) => t.id == tableId).firstOrNull;
    return t?.label ?? tableId;
  }

  void addRestaurantTable(RestaurantTable table) {
    _restaurantTables.add(table);
    notifyListeners();
  }

  void updateRestaurantTable(RestaurantTable table) {
    final index = _restaurantTables.indexWhere((t) => t.id == table.id);
    if (index != -1) {
      _restaurantTables[index] = table;
      notifyListeners();
    }
  }

  void removeRestaurantTable(String id) {
    _restaurantTables.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  bool isTableAvailable(String tableId, DateTime date, RestaurantShift shift,
      {String? excludingBookingId}) {
    return !_tableBookings.any((b) =>
        b.id != excludingBookingId &&
        b.tableId == tableId &&
        b.shift == shift &&
        b.status != TableBookingStatus.cancelled &&
        b.isOnDay(date));
  }

  /// All active table bookings on [tableId] for [date]/[shift] (normally at
  /// most one, since [addTableBooking]/[updateTableBooking] enforce that).
  List<TableBooking> tableBookingsFor(String tableId, DateTime date, RestaurantShift shift) {
    return _tableBookings
        .where((b) =>
            b.tableId == tableId &&
            b.shift == shift &&
            b.status != TableBookingStatus.cancelled &&
            b.isOnDay(date))
        .toList();
  }

  /// Suggests the smallest available table that seats [partySize] for
  /// [date]/[shift], or null if none fit.
  RestaurantTable? suggestTableFor(DateTime date, RestaurantShift shift, int partySize) {
    final candidates = _restaurantTables
        .where((t) => t.seats >= partySize && isTableAvailable(t.id, date, shift))
        .toList()
      ..sort((a, b) => a.seats.compareTo(b.seats));
    return candidates.firstOrNull;
  }

  String? addTableBooking(TableBooking booking) {
    if (!isTableAvailable(booking.tableId, booking.date, booking.shift)) {
      return 'Tavolo ${restaurantTableLabel(booking.tableId)} già occupato per quel turno.';
    }
    _tableBookings.add(booking);
    notifyListeners();
    return null;
  }

  String? updateTableBooking(TableBooking booking) {
    final index = _tableBookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) return 'Prenotazione non trovata';
    if (!isTableAvailable(booking.tableId, booking.date, booking.shift,
        excludingBookingId: booking.id)) {
      return 'Tavolo ${restaurantTableLabel(booking.tableId)} già occupato per quel turno.';
    }
    _tableBookings[index] = booking;
    notifyListeners();
    return null;
  }

  void deleteTableBooking(String id) {
    _tableBookings.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void performTableCheckIn(String bookingId) {
    final index = _tableBookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;
    _tableBookings[index] = _tableBookings[index]
        .copyWith(checkedIn: true, status: TableBookingStatus.seated);
    notifyListeners();
  }

  List<TableBooking> getUserTableBookings(String userId) {
    return _tableBookings.where((b) => b.userId == userId).toList();
  }

  /// Cross-reference helper for the operator: does this customer (by userId)
  /// also have a beach umbrella booking? Lets the restaurant booking view
  /// surface "also has a beach booking" and vice versa.
  bool userHasBeachBooking(String userId) =>
      _bookings.any((b) => b.userId == userId);

  bool userHasRestaurantBooking(String userId) =>
      _tableBookings.any((b) => b.userId == userId);

  Future<void> _persistTableBookings() async {
    if (!_readyToPersistBookings) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tableBookings.map((b) => b.toJson()).toList();
      await prefs.setString(_tableBookingsStorageKey, jsonEncode(jsonList));
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _hydrateTableBookingsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tableBookingsStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final restored = decoded
            .map((e) => TableBooking.fromJson(e as Map<String, dynamic>))
            .toList();
        _tableBookings
          ..clear()
          ..addAll(restored);
      }
    } catch (_) {
      // Corrupt/incompatible stored data: keep the freshly-seeded demo state.
    }
  }

  // --- Extra services marketplace ---

  List<ExtraServiceItem> get extraServiceItems => List.unmodifiable(_extraServiceItems);
  List<ExtraServiceItem> get availableExtraServiceItems =>
      _extraServiceItems.where((i) => i.available).toList();
  List<ExtraPriceListEntry> get extraPriceList => List.unmodifiable(_extraPriceList);
  List<ExtraServiceOrder> get extraServiceOrders =>
      List.unmodifiable(_extraServiceOrders.reversed); // newest first
  int get pendingExtraOrdersCount =>
      _extraServiceOrders.where((o) => o.status == ExtraOrderStatus.pending).length;

  void addExtraServiceItem(ExtraServiceItem item) {
    _extraServiceItems.add(item);
    notifyListeners();
  }

  void updateExtraServiceItem(ExtraServiceItem item) {
    final index = _extraServiceItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _extraServiceItems[index] = item;
      notifyListeners();
    }
  }

  void deleteExtraServiceItem(String id) {
    _extraServiceItems.removeWhere((i) => i.id == id);
    _extraPriceList.removeWhere((p) => p.itemId == id);
    notifyListeners();
  }

  void addExtraPriceListEntry(ExtraPriceListEntry entry) {
    _extraPriceList.add(entry);
    notifyListeners();
  }

  void updateExtraPriceListEntry(ExtraPriceListEntry entry) {
    final index = _extraPriceList.indexWhere((p) => p.id == entry.id);
    if (index != -1) {
      _extraPriceList[index] = entry;
      notifyListeners();
    }
  }

  void deleteExtraPriceListEntry(String id) {
    _extraPriceList.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Resolves the price for [itemId] on [date]: the active season's
  /// weekday/Fri/Sat/Sun price if one exists, otherwise the item's flat
  /// [ExtraServiceItem.defaultPrice] — same fallback chain as
  /// priceForPackageOnUmbrella for the beach price list.
  double priceForExtraService(String itemId, DateTime date) {
    final item = _extraServiceItems.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return 0.0;
    final season = activeSeasonOn(date);
    if (season != null) {
      final entry = _extraPriceList
          .where((p) => p.itemId == itemId && p.seasonId == season.id)
          .firstOrNull;
      if (entry != null) return entry.getPriceForDate(date);
    }
    return item.defaultPrice;
  }

  /// Places a customer order and makes it visible to the operator the
  /// instant it's created (both sides share this same ChangeNotifier, so
  /// the admin "Ordini Extra" screen updates live via notifyListeners).
  ExtraServiceOrder placeExtraServiceOrder({
    required String userId,
    required String customerName,
    required String itemId,
    int quantity = 1,
    String? umbrellaId,
    String? notes,
  }) {
    final unitPrice = priceForExtraService(itemId, DateTime.now());
    final order = ExtraServiceOrder(
      id: const Uuid().v4(),
      userId: userId,
      customerName: customerName,
      itemId: itemId,
      quantity: quantity,
      umbrellaId: umbrellaId,
      totalPrice: unitPrice * quantity,
      notes: notes,
    );
    _extraServiceOrders.add(order);
    final item = _extraServiceItems.where((i) => i.id == itemId).firstOrNull;
    _pushNotification(
      title: 'Nuovo ordine extra',
      body: '$customerName · ${item?.name ?? itemId} x$quantity'
          '${umbrellaId != null ? ' · Ombrellone ${umbrellaLabel(umbrellaId)}' : ''}',
      type: AppNotificationType.order,
      refId: order.id,
    );
    return order;
  }

  void updateExtraOrderStatus(String orderId, ExtraOrderStatus status) {
    final index = _extraServiceOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _extraServiceOrders[index] = _extraServiceOrders[index].copyWith(status: status);
      notifyListeners();
    }
  }

  List<ExtraServiceOrder> getUserExtraServiceOrders(String userId) =>
      _extraServiceOrders.where((o) => o.userId == userId).toList().reversed.toList();

  Future<void> _persistExtraOrders() async {
    if (!_readyToPersistBookings) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _extraServiceOrders.map((o) => o.toJson()).toList();
      await prefs.setString(_extraOrdersStorageKey, jsonEncode(jsonList));
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _hydrateExtraOrdersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_extraOrdersStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final restored =
            decoded.map((e) => ExtraServiceOrder.fromJson(e as Map<String, dynamic>)).toList();
        _extraServiceOrders
          ..clear()
          ..addAll(restored);
      }
    } catch (_) {
      // Corrupt/incompatible stored data: keep the freshly-seeded demo state.
    }
  }
}

enum CheckInStatus { valid, expired, future, notFound }

class CheckInResult {
  final bool isValid;
  final CheckInStatus status;
  final String message;
  final Booking? booking;
  
  CheckInResult({
    required this.isValid,
    required this.status,
    required this.message,
    this.booking,
  });
}
