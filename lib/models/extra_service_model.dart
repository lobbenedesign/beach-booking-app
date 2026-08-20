/// On-demand extra services purchasable any time from the customer app —
/// distinct from [ExtraService]/[BookingExtra] (beach_model.dart), which are
/// day-by-day equipment add-ons attached to a multi-day umbrella stay (e.g.
/// "add a sunbed for 2 of 7 days"). These are one-off consumption items: bar
/// orders, timed activity rentals (canoe/boat/beach-tennis court), or a
/// service delivered at the customer's umbrella (massage, welcome spritz).
library;

enum ExtraServiceCategory { bar, rental, court, umbrellaService }

extension ExtraServiceCategoryX on ExtraServiceCategory {
  String get label {
    switch (this) {
      case ExtraServiceCategory.bar:
        return 'Bar';
      case ExtraServiceCategory.rental:
        return 'Noleggio';
      case ExtraServiceCategory.court:
        return 'Campo';
      case ExtraServiceCategory.umbrellaService:
        return 'Servizio in spiaggia';
    }
  }
}

/// A sellable extra — e.g. "Canoa singola" (rental, 60 min, capacity 1),
/// "Spritz aperitivo" (bar), "Massaggio relax" (umbrellaService).
class ExtraServiceItem {
  final String id;
  String name;
  String description;
  ExtraServiceCategory category;
  int? durationMinutes; // set for timed rentals/court bookings
  int? capacity; // e.g. 1 = singola, 2 = doppia, for canoe/pedalo
  double defaultPrice; // fallback if no seasonal price-list entry matches
  String? iconImage;
  bool available;

  ExtraServiceItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.durationMinutes,
    this.capacity,
    this.defaultPrice = 0.0,
    this.iconImage,
    this.available = true,
  });
}

/// Seasonal/weekday price override for one [ExtraServiceItem] — same
/// weekday/Fri/Sat/Sun differentiation as the beach package price list
/// (PriceListEntry in beach_model.dart), just without a zone dimension since
/// extras aren't tied to a specific umbrella position.
class ExtraPriceListEntry {
  final String id;
  final String itemId;
  final String seasonId;
  final double weekdayPrice;
  final double? fridayPrice;
  final double? saturdayPrice;
  final double? sundayPrice;

  ExtraPriceListEntry({
    required this.id,
    required this.itemId,
    required this.seasonId,
    required this.weekdayPrice,
    this.fridayPrice,
    this.saturdayPrice,
    this.sundayPrice,
  });

  double getPriceForDate(DateTime date) {
    final day = date.weekday; // 1=Mon .. 7=Sun
    if (day == 7 && sundayPrice != null) return sundayPrice!;
    if (day == 6 && saturdayPrice != null) return saturdayPrice!;
    if (day == 5 && fridayPrice != null) return fridayPrice!;
    return weekdayPrice;
  }
}

enum ExtraOrderStatus { pending, confirmed, delivered, cancelled }

extension ExtraOrderStatusX on ExtraOrderStatus {
  String get label {
    switch (this) {
      case ExtraOrderStatus.pending:
        return 'In arrivo';
      case ExtraOrderStatus.confirmed:
        return 'Confermato';
      case ExtraOrderStatus.delivered:
        return 'Consegnato';
      case ExtraOrderStatus.cancelled:
        return 'Annullato';
    }
  }
}

/// One customer order for an [ExtraServiceItem], placed from the app and
/// meant to reach the operator immediately (the admin "Ordini Extra" screen
/// listens to the same MockDataService instance, so a new order appears the
/// moment it's placed).
class ExtraServiceOrder {
  final String id;
  final String userId;
  final String customerName;
  final String itemId;
  final int quantity;
  final DateTime requestedAt;
  final String? umbrellaId; // set when delivered at a specific umbrella
  final double totalPrice;
  final String? notes;
  ExtraOrderStatus status;

  ExtraServiceOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.itemId,
    this.quantity = 1,
    DateTime? requestedAt,
    this.umbrellaId,
    required this.totalPrice,
    this.notes,
    this.status = ExtraOrderStatus.pending,
  }) : requestedAt = requestedAt ?? DateTime.now();

  ExtraServiceOrder copyWith({ExtraOrderStatus? status}) => ExtraServiceOrder(
        id: id,
        userId: userId,
        customerName: customerName,
        itemId: itemId,
        quantity: quantity,
        requestedAt: requestedAt,
        umbrellaId: umbrellaId,
        totalPrice: totalPrice,
        notes: notes,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'customerName': customerName,
        'itemId': itemId,
        'quantity': quantity,
        'requestedAt': requestedAt.toIso8601String(),
        'umbrellaId': umbrellaId,
        'totalPrice': totalPrice,
        'notes': notes,
        'status': status.name,
      };

  factory ExtraServiceOrder.fromJson(Map<String, dynamic> json) => ExtraServiceOrder(
        id: json['id'] as String,
        userId: json['userId'] as String,
        customerName: json['customerName'] as String,
        itemId: json['itemId'] as String,
        quantity: json['quantity'] as int? ?? 1,
        requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt'] as String) : null,
        umbrellaId: json['umbrellaId'] as String?,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        status: ExtraOrderStatus.values.byName(json['status'] as String? ?? 'pending'),
      );
}
