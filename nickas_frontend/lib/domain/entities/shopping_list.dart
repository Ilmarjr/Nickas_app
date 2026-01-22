import 'package:uuid/uuid.dart';
import 'item.dart';

class ShoppingList {
  final String id;
  final String name;
  final DateTime date;
  final bool isDeleted;
  final DateTime? lastSynced;
  // Items are usually loaded separately or eagerly.
  // keeping a list here helps in UI state.
  // Stats for UI performance (avoid loading full item list just for headers)
  final List<Item> items;
  final double? summaryTotal; // Transient field for list views

  ShoppingList({
    String? id,
    required this.name,
    required this.date,
    this.isDeleted = false,
    this.lastSynced,
    this.items = const [],
    this.summaryTotal,
  }) : id = id ?? const Uuid().v4();

  double get total =>
      items.fold(0, (sum, item) => sum + (item.isChecked ? item.total : 0));
  double get estimatedTotal => items.fold(0, (sum, item) => sum + item.total);

  ShoppingList copyWith({
    String? name,
    DateTime? date,
    bool? isDeleted,
    DateTime? lastSynced,
    List<Item>? items,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSynced: lastSynced ?? this.lastSynced,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'date': date.toIso8601String()};
  }
}
