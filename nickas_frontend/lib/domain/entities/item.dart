import 'package:uuid/uuid.dart';

class Item {
  final String id;
  final String listId;
  final String name;
  final String brand; // Added as per requirements
  final double quantity;
  final double price; // Unitarian price, 0.0 if not set
  final bool isChecked;
  final bool isDeleted; // Soft delete
  final DateTime? lastSynced;

  Item({
    String? id,
    required this.listId,
    required this.name,
    this.brand = '',
    this.quantity = 1.0,
    this.price = 0.0,
    this.isChecked = false,
    this.isDeleted = false,
    this.lastSynced,
  }) : id = id ?? const Uuid().v4();

  double get total => quantity * price;

  // CopyWith for immutability updates
  Item copyWith({
    String? name,
    String? brand,
    double? quantity,
    double? price,
    bool? isChecked,
    bool? isDeleted,
    DateTime? lastSynced,
  }) {
    return Item(
      id: id,
      listId: listId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      isChecked: isChecked ?? this.isChecked,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'price': price,
      'isChecked': isChecked ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      // Dates usually stored as info, but for sqlite we might use string or int
      // We'll standardise specific DB mapping in Data Models if strictly separating,
      // but for simple Flutter apps often Entity has toJson.
      // We will stick to clean arch: Entity shouldn't know about JSON/DB,
      // but keeping toMap here is pragmatic for MVP if we use it directly.
      // Let's keep it pure-ish.
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'price': price,
      'is_checked': isChecked,
    };
  }
}
