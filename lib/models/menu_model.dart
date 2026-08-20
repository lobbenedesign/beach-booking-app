import 'package:flutter/material.dart';

enum OrderStatus { pending, preparing, ready, served, cancelled }

class MenuCategory {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final IconData? icon;

  MenuCategory({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.icon,
  });

  MenuCategory copyWith({
    String? id,
    String? name,
    String? description,
    int? sortOrder,
    IconData? icon,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      icon: icon ?? this.icon,
    );
  }
}

/// Standard allergen labels (Reg. UE 1169/2011) offered when tagging a dish.
const List<String> kStandardAllergens = [
  'Glutine',
  'Crostacei',
  'Uova',
  'Pesce',
  'Arachidi',
  'Soia',
  'Latte',
  'Frutta a guscio',
  'Sedano',
  'Senape',
  'Sesamo',
  'Anidride solforosa',
  'Lupini',
  'Molluschi',
];

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final bool isAvailable;
  final String? imageUrl; // data: URL (uploaded photo) or asset path
  final List<String>? allergens; // e.g., ['Glutine', 'Latte']
  final int sortOrder;

  /// Minimum quantity that can be ordered at once (e.g. a risotto made for
  /// at least 2 people). 1 = no minimum.
  final int minOrderQuantity;

  /// Optional human-readable override for the minimum-order note shown to
  /// the customer (e.g. "Minimo per 2 persone"). If null but
  /// [minOrderQuantity] > 1, a default note is derived from it.
  final String? minOrderNote;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.isAvailable = true,
    this.imageUrl,
    this.allergens,
    this.sortOrder = 0,
    this.minOrderQuantity = 1,
    this.minOrderNote,
  });

  bool get hasMinimumOrder => minOrderQuantity > 1;

  String? get effectiveMinOrderNote {
    if (minOrderNote != null && minOrderNote!.isNotEmpty) return minOrderNote;
    if (hasMinimumOrder) return 'Minimo $minOrderQuantity persone';
    return null;
  }

  MenuItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    bool? isAvailable,
    String? imageUrl,
    List<String>? allergens,
    int? sortOrder,
    int? minOrderQuantity,
    String? minOrderNote,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      allergens: allergens ?? this.allergens,
      sortOrder: sortOrder ?? this.sortOrder,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      minOrderNote: minOrderNote ?? this.minOrderNote,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String menuItemName;
  final double unitPrice;
  final int quantity;
  final String? notes; // e.g., "Senza cipolla"

  OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  double get totalPrice => unitPrice * quantity;

  OrderItem copyWith({
    String? menuItemId,
    String? menuItemName,
    double? unitPrice,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class Order {
  final String id;
  final String? umbrellaId; // Null if order is from bar/restaurant directly
  final String? umbrellaLabel; // e.g., "A-5"
  final String? customerName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  Order({
    required this.id,
    this.umbrellaId,
    this.umbrellaLabel,
    this.customerName,
    required this.items,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Order copyWith({
    String? id,
    String? umbrellaId,
    String? umbrellaLabel,
    String? customerName,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      umbrellaId: umbrellaId ?? this.umbrellaId,
      umbrellaLabel: umbrellaLabel ?? this.umbrellaLabel,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
