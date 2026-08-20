import 'package:flutter/material.dart';

enum UmbrellaStatus { available, occupied, reserved, maintenance }

/// Status of an umbrella for a specific day, used by the operator's daily map.
enum UmbrellaDayStatus {
  free, // not booked
  bookedOnline, // booked through the app
  bookedOnSite, // walk-in registered by the operator
  checkedIn, // customer has arrived and checked in
  absentResellable, // owner flagged absence: operator may resell for the day
}

enum MapElementType {
  // Terrain
  sand, sea, rock, walkway, grass,
  // Facilities
  wc, wcDisabled, playground, lifeguardTower, lighthouse, ticketOffice, kiosk, bar, restaurant, lounge,
  // Rentals
  umbrella, sunbed, deckchair, pedalo, canoe, boat, surf, windsurf, bungalow, pagoda, canopy, kingSizeBed,
  // Infrastructure
  dock, wall,
  // Decorations
  palm, plant, flower, bench,
  // Structures
  shower, cabin, gazebo, umbrellaStand, fence,
  // Additional Services
  firstAid, parking, entrance,
  // Zones/Areas
  zone
}

class MapElement {
  String id;
  MapElementType type;
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double width; // relative size
  double height; // relative size
  Color? color; // Custom color override
  String? label; // Custom label (e.g. "Bar", "A-1")
  int rotation; // 0, 90, 180, 270
  
  // Transformation properties
  double scaleX; // Scale factor for width (default 1.0)
  double scaleY; // Scale factor for height (default 1.0)
  bool flipHorizontal; // Flip horizontally
  bool flipVertical; // Flip vertically
  
  // Zone/Area properties (for type == zone)
  List<Offset>? customPath; // Free-form shape path (if null, use rectangle)
  Color? borderColor; // Border color for zones
  double borderWidth; // Border width in pixels
  Color? fillColor; // Fill color for zones
  double fillOpacity; // Fill opacity (0.0 to 1.0)
  String? zoneTitle; // Title/label for the zone
  
  // Specific data for umbrellas/rentals
  int? row;
  int? number;
  UmbrellaStatus status;
  String? zoneId;

  MapElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.width = 0.05,
    this.height = 0.05,
    this.color,
    this.label,
    this.rotation = 0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.customPath,
    this.borderColor,
    this.borderWidth = 2.0,
    this.fillColor,
    this.fillOpacity = 0.3,
    this.zoneTitle,
    this.row,
    this.number,
    this.status = UmbrellaStatus.available,
    this.zoneId,
    this.iconImage,
  });

  // Optional raster image override (data URL) shown instead of the built-in
  // icon/SVG for this specific element — e.g. a photo of the actual sunbed
  // model, distinct from the beach-wide background photo.
  String? iconImage;

  /// Independent snapshot of every field, decoupled from further in-place
  /// mutation of the original — needed because [MockDataService] stores and
  /// hands out the same mutable object it keeps internally, so editor code
  /// that wants an undo/redo "before" state must clone it before mutating.
  MapElement clone() => MapElement(
        id: id,
        type: type,
        x: x,
        y: y,
        width: width,
        height: height,
        color: color,
        label: label,
        rotation: rotation,
        scaleX: scaleX,
        scaleY: scaleY,
        flipHorizontal: flipHorizontal,
        flipVertical: flipVertical,
        customPath: customPath == null ? null : List.of(customPath!),
        borderColor: borderColor,
        borderWidth: borderWidth,
        fillColor: fillColor,
        fillOpacity: fillOpacity,
        zoneTitle: zoneTitle,
        row: row,
        number: number,
        status: status,
        zoneId: zoneId,
        iconImage: iconImage,
      );
}

enum PricingType { fixed, percentage }

class BeachZone {
  final String id;
  final String name;
  final Color color;
  final PricingType pricingType;
  final double value; // Fixed amount (e.g. 10.0) or Percentage (e.g. 20.0 for 20%)

  BeachZone({
    required this.id,
    required this.name,
    required this.color,
    this.pricingType = PricingType.percentage,
    this.value = 0.0,
  });
  
  // Helper to get legacy multiplier for backward compatibility if needed, 
  // though we should switch to using value/type logic.
  double get priceMultiplier => pricingType == PricingType.percentage ? (1 + value / 100) : 1.0;
}

class Season {
  final String id;
  String name;
  DateTime startDate;
  DateTime endDate;
  
  Season({required this.id, required this.name, required this.startDate, required this.endDate});
}

class PriceListEntry {
  final String id;
  final String packageId;
  final String zoneId;
  final String seasonId;
  
  // Map of Weekday (1=Mon, 7=Sun) to Price
  // If a key is missing, fallback to weekdayPrice or base.
  // Simplest is to require all days or use a logic. 
  // User wants explicit "Weekend", "Pre-weekend". 
  // We will store specific overrides.
  final double weekdayPrice; // Base price for Mon-Thu
  final double? fridayPrice; 
  final double? saturdayPrice;
  final double? sundayPrice;
  
  PriceListEntry({
    required this.id, 
    required this.packageId, 
    required this.zoneId, 
    required this.seasonId, 
    required this.weekdayPrice,
    this.fridayPrice,
    this.saturdayPrice,
    this.sundayPrice,
  });

  double getPriceForDate(DateTime date) {
    // 1 = Mon, ..., 7 = Sun
    final day = date.weekday;
    if (day == 7 && sundayPrice != null) return sundayPrice!;
    if (day == 6 && saturdayPrice != null) return saturdayPrice!;
    if (day == 5 && fridayPrice != null) return fridayPrice!;
    return weekdayPrice;
  }
}

class ServicePackage {
  final String id;
  String name;
  List<String> items; // e.g., ["Ombrellone", "Lettino", "Sdraio"]
  String description;
  double defaultBasePrice; // Fallback if no specific price entry found
  String? iconImage; // Optional raster photo (data URL) shown in package pickers

  ServicePackage({
    required this.id,
    required this.name,
    required this.items,
    this.description = '',
    this.defaultBasePrice = 0.0,
    this.iconImage,
  });
}

class PriceRule {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? daysOfWeek; // 1 = Monday, 7 = Sunday
  final PricingType pricingType;
  final double value;

  PriceRule({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.daysOfWeek,
    this.pricingType = PricingType.percentage,
    this.value = 0.0,
  });
}

// Extra Equipment (chairs, sunbeds, etc.)
class ExtraEquipment {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? imageUrl;

  ExtraEquipment({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.available = true,
    this.imageUrl,
  });
}

// Extra Services (welcome drinks, massages, etc.)
class ExtraService {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? imageUrl;

  ExtraService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.available = true,
    this.imageUrl,
  });
}

// Booking Extra (equipment or service added to a booking)
class BookingExtra {
  final String id; // equipment or service id
  final String name;
  final double price; // price per unit per day
  final int quantity;
  final bool isService; // true for service, false for equipment

  /// Days within the booking this extra applies to.
  /// Null or empty = applies to every day of the stay (legacy behaviour).
  final List<DateTime>? forDates;

  BookingExtra({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.isService,
    this.forDates,
  });

  bool get isPartialStay => forDates != null && forDates!.isNotEmpty;

  bool appliesOn(DateTime day) {
    if (!isPartialStay) return true;
    return forDates!.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'isService': isService,
        'forDates': forDates?.map((d) => d.toIso8601String()).toList(),
      };

  factory BookingExtra.fromJson(Map<String, dynamic> json) => BookingExtra(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
        isService: json['isService'] as bool,
        forDates: (json['forDates'] as List<dynamic>?)
            ?.map((s) => DateTime.parse(s as String))
            .toList(),
      );
}

enum BookingStatus { pending, confirmed, cancelled, completed }

/// How the booking entered the system.
/// - online: customer booked through the app
/// - onSite: operator registered a walk-in customer at the facility
enum BookingChannel { online, onSite }

/// Discount coupon that customers can apply at checkout.
class Coupon {
  final String code;
  final PricingType type; // fixed amount or percentage
  final double value;
  final bool active;
  final DateTime? expiresAt;

  Coupon({
    required this.code,
    this.type = PricingType.percentage,
    this.value = 0,
    this.active = true,
    this.expiresAt,
  });

  bool get isValid =>
      active && (expiresAt == null || DateTime.now().isBefore(expiresAt!));

  /// Discount amount for a given [subtotal], never exceeding it.
  double discountFor(double subtotal) {
    final d = type == PricingType.percentage ? subtotal * value / 100 : value;
    return d.clamp(0, subtotal).toDouble();
  }
}

class Booking {
  final String id;
  final String umbrellaId;
  final String userId;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final BookingStatus status;
  final double totalPrice;
  final bool isPaid;
  final String? packageId;
  final List<BookingExtra> extras;

  // Fee breakdown
  final double subtotal;
  final double bookingFee;
  final double vat;
  final double paymentFee;

  // Discounts & partial payment
  final double discountAmount;
  final String? couponCode;
  final double deposit; // amount already paid (acconto); 0 = none

  // Check-in / check-out tracking
  final bool checkedIn;
  final bool checkedOut;

  // Channel, absence and sharing
  final BookingChannel channel;
  final List<DateTime> absentDates; // days the owner flagged as absent
  final String? shareCode; // active share code generated by the owner
  final String? sharedFromBookingId; // set on the recipient's imported copy

  /// When the booking was made (defaults to now at construction time).
  /// Used to distinguish last-minute from seasonal/advance bookings.
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.umbrellaId,
    required this.userId,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    this.status = BookingStatus.confirmed,
    required this.totalPrice,
    this.isPaid = false,
    this.packageId,
    this.extras = const [],
    this.subtotal = 0.0,
    this.bookingFee = 0.0,
    this.vat = 0.0,
    this.paymentFee = 0.0,
    this.discountAmount = 0.0,
    this.couponCode,
    this.deposit = 0.0,
    this.checkedIn = false,
    this.checkedOut = false,
    this.channel = BookingChannel.online,
    this.absentDates = const [],
    this.shareCode,
    this.sharedFromBookingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool isAbsentOn(DateTime day) =>
      absentDates.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);

  /// Outstanding balance still due at the facility.
  double get balanceDue {
    if (isPaid) return 0;
    final due = totalPrice - deposit;
    return due < 0 ? 0 : due;
  }

  bool get isDeposit => deposit > 0 && deposit < totalPrice;

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Long-stay booking (typically a season-long reservation on the same spot).
  bool get isSeasonal => durationInDays >= 21;

  /// Booked with little notice before arrival, and for a short stay.
  bool get isLastMinute =>
      !isSeasonal &&
      durationInDays <= 3 &&
      startDate.difference(createdAt).inHours <= 48;

  Booking copyWith({
    BookingStatus? status,
    bool? isPaid,
    bool? checkedIn,
    bool? checkedOut,
    String? umbrellaId,
    BookingChannel? channel,
    List<DateTime>? absentDates,
    String? shareCode,
    List<BookingExtra>? extras,
    double? totalPrice,
    double? subtotal,
    String? customerName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Booking(
      id: id,
      umbrellaId: umbrellaId ?? this.umbrellaId,
      userId: userId,
      customerName: customerName ?? this.customerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      isPaid: isPaid ?? this.isPaid,
      packageId: packageId,
      extras: extras ?? this.extras,
      subtotal: subtotal ?? this.subtotal,
      bookingFee: bookingFee,
      vat: vat,
      paymentFee: paymentFee,
      discountAmount: discountAmount,
      couponCode: couponCode,
      deposit: deposit,
      checkedIn: checkedIn ?? this.checkedIn,
      checkedOut: checkedOut ?? this.checkedOut,
      channel: channel ?? this.channel,
      absentDates: absentDates ?? this.absentDates,
      shareCode: shareCode ?? this.shareCode,
      sharedFromBookingId: sharedFromBookingId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'umbrellaId': umbrellaId,
        'userId': userId,
        'customerName': customerName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status.name,
        'totalPrice': totalPrice,
        'isPaid': isPaid,
        'packageId': packageId,
        'extras': extras.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'bookingFee': bookingFee,
        'vat': vat,
        'paymentFee': paymentFee,
        'discountAmount': discountAmount,
        'couponCode': couponCode,
        'deposit': deposit,
        'checkedIn': checkedIn,
        'checkedOut': checkedOut,
        'channel': channel.name,
        'absentDates': absentDates.map((d) => d.toIso8601String()).toList(),
        'shareCode': shareCode,
        'sharedFromBookingId': sharedFromBookingId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        umbrellaId: json['umbrellaId'] as String,
        userId: json['userId'] as String,
        customerName: json['customerName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        status: BookingStatus.values.byName(json['status'] as String),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        isPaid: json['isPaid'] as bool? ?? false,
        packageId: json['packageId'] as String?,
        extras: (json['extras'] as List<dynamic>? ?? [])
            .map((e) => BookingExtra.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        bookingFee: (json['bookingFee'] as num?)?.toDouble() ?? 0.0,
        vat: (json['vat'] as num?)?.toDouble() ?? 0.0,
        paymentFee: (json['paymentFee'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        couponCode: json['couponCode'] as String?,
        deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
        checkedIn: json['checkedIn'] as bool? ?? false,
        checkedOut: json['checkedOut'] as bool? ?? false,
        channel: BookingChannel.values.byName(json['channel'] as String? ?? 'online'),
        absentDates: (json['absentDates'] as List<dynamic>? ?? [])
            .map((s) => DateTime.parse(s as String))
            .toList(),
        shareCode: json['shareCode'] as String?,
        sharedFromBookingId: json['sharedFromBookingId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

/// A partial-booking share the owner grants to another user for a date window.
class BookingShare {
  final String code;
  final String bookingId;
  final String ownerUserId;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  String? claimedByUserId;
  DateTime? claimedAt;

  BookingShare({
    required this.code,
    required this.bookingId,
    required this.ownerUserId,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    this.claimedByUserId,
    this.claimedAt,
  });

  bool get isClaimed => claimedByUserId != null;
}

// Payment & Locking Models


enum LockStatus { active, expired }

class UmbrellaLock {
  final String umbrellaId;
  final String userId;
  final DateTime lockTime;
  final DateTime expirationTime;

  UmbrellaLock({
    required this.umbrellaId,
    required this.userId,
    required this.lockTime,
    required this.expirationTime,
  });

  bool get isExpired => DateTime.now().isAfter(expirationTime);
  
  LockStatus get status => isExpired ? LockStatus.expired : LockStatus.active;
}

enum PaymentProvider { stripe, paypal, manual }

class FinancialSettings {
  String iban;
  String companyName;
  String companyVatNumber;
  String companyAddress;
  
  // Stripe
  String stripePublicKey;
  String stripeSecretKey; // In real app, never store secret key on client!
  bool stripeEnabled;
  
  // PayPal
  String paypalClientId;
  String paypalSecret;
  bool paypalEnabled;

  FinancialSettings({
    this.iban = '',
    this.companyName = '',
    this.companyVatNumber = '',
    this.companyAddress = '',
    this.stripePublicKey = '',
    this.stripeSecretKey = '',
    this.stripeEnabled = false,
    this.paypalClientId = '',
    this.paypalSecret = '',
    this.paypalEnabled = false,
  });
}

class Transaction {
  final String id;
  final String bookingId;
  final double amount;
  final DateTime date;
  final PaymentProvider provider;
  final String status; // 'completed', 'pending', 'failed'
  final String? externalReference; // Transaction ID from Stripe/PayPal

  Transaction({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.date,
    required this.provider,
    required this.status,
    this.externalReference,
  });
}
