/// Restaurant table map + booking models. Mirrors the beach's
/// MapElement/Booking pair, but scoped to the restaurant floor plan: tables
/// instead of umbrellas, lunch/dinner shifts instead of a date range, party
/// size + allergy notes instead of packages/extras.
library;

enum TableShape { round, square, rectangle }

/// A named area of the restaurant floor plan (e.g. "Interno", "Terrazza",
/// "Giardino") — mirrors the beach's [BeachZone], minus per-zone pricing
/// (table bookings use a flat per-cover charge, not zone-based pricing).
class RestaurantZone {
  final String id;
  final String name;
  final int colorValue; // ARGB, stored as int so the model has no Flutter dependency

  RestaurantZone({required this.id, required this.name, required this.colorValue});
}

enum RestaurantShift { pranzo, cena }

extension RestaurantShiftX on RestaurantShift {
  String get label => this == RestaurantShift.pranzo ? 'Pranzo' : 'Cena';
  String get timeRange =>
      this == RestaurantShift.pranzo ? '12:30 - 15:00' : '19:30 - 23:00';
}

class RestaurantTable {
  final String id;
  double x; // 0.0 - 1.0, relative to the floor plan canvas
  double y;
  double width;
  double height;
  int seats;
  TableShape shape;
  String? label;
  int rotation;
  String? zoneId;

  RestaurantTable({
    required this.id,
    required this.x,
    required this.y,
    this.width = 0.08,
    this.height = 0.08,
    this.seats = 4,
    this.shape = TableShape.round,
    this.label,
    this.rotation = 0,
    this.zoneId,
  });

  /// Independent snapshot of every field, decoupled from further in-place
  /// mutation of the original — needed because [MockDataService] stores and
  /// hands out the same mutable object it keeps internally, so editor code
  /// that wants an undo/redo "before" state must clone it before mutating.
  RestaurantTable clone() => RestaurantTable(
        id: id,
        x: x,
        y: y,
        width: width,
        height: height,
        seats: seats,
        shape: shape,
        label: label,
        rotation: rotation,
        zoneId: zoneId,
      );
}

enum TableBookingStatus { confirmed, seated, completed, cancelled }

class TableBooking {
  final String id;
  final String tableId;
  final String userId;
  final String customerName;
  final DateTime date; // day only (time-of-day carried by shift)
  final RestaurantShift shift;
  final int partySize;
  final String? allergyNotes;
  final String? phone;
  final TableBookingStatus status;
  final bool checkedIn;
  final DateTime createdAt;

  // Billing: a per-cover charge (partySize * coverCharge) at the moment of
  // booking, plus any manual adjustment; tracked like the beach Booking so
  // the operator can mark it paid / see the balance due.
  final double totalPrice;
  final bool isPaid;
  final double deposit;

  TableBooking({
    required this.id,
    required this.tableId,
    required this.userId,
    required this.customerName,
    required this.date,
    required this.shift,
    required this.partySize,
    this.allergyNotes,
    this.phone,
    this.status = TableBookingStatus.confirmed,
    this.checkedIn = false,
    DateTime? createdAt,
    this.totalPrice = 0,
    this.isPaid = false,
    this.deposit = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool isOnDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  double get balanceDue {
    if (isPaid) return 0;
    final due = totalPrice - deposit;
    return due < 0 ? 0 : due;
  }

  TableBooking copyWith({
    String? tableId,
    String? customerName,
    DateTime? date,
    RestaurantShift? shift,
    int? partySize,
    String? allergyNotes,
    String? phone,
    TableBookingStatus? status,
    bool? checkedIn,
    double? totalPrice,
    bool? isPaid,
    double? deposit,
  }) =>
      TableBooking(
        id: id,
        tableId: tableId ?? this.tableId,
        userId: userId,
        customerName: customerName ?? this.customerName,
        date: date ?? this.date,
        shift: shift ?? this.shift,
        partySize: partySize ?? this.partySize,
        allergyNotes: allergyNotes ?? this.allergyNotes,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        checkedIn: checkedIn ?? this.checkedIn,
        createdAt: createdAt,
        totalPrice: totalPrice ?? this.totalPrice,
        isPaid: isPaid ?? this.isPaid,
        deposit: deposit ?? this.deposit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'userId': userId,
        'customerName': customerName,
        'date': date.toIso8601String(),
        'shift': shift.name,
        'partySize': partySize,
        'allergyNotes': allergyNotes,
        'phone': phone,
        'status': status.name,
        'checkedIn': checkedIn,
        'createdAt': createdAt.toIso8601String(),
        'totalPrice': totalPrice,
        'isPaid': isPaid,
        'deposit': deposit,
      };

  factory TableBooking.fromJson(Map<String, dynamic> json) => TableBooking(
        id: json['id'] as String,
        tableId: json['tableId'] as String,
        userId: json['userId'] as String,
        customerName: json['customerName'] as String,
        date: DateTime.parse(json['date'] as String),
        shift: RestaurantShift.values.byName(json['shift'] as String),
        partySize: json['partySize'] as int? ?? 2,
        allergyNotes: json['allergyNotes'] as String?,
        phone: json['phone'] as String?,
        status: TableBookingStatus.values
            .byName(json['status'] as String? ?? 'confirmed'),
        checkedIn: json['checkedIn'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
        isPaid: json['isPaid'] as bool? ?? false,
        deposit: (json['deposit'] as num?)?.toDouble() ?? 0,
      );
}
