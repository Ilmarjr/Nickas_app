class CategoryModel {
  final String id;
  final String name;
  final String color; // Hex string e.g., "#FF0000"
  final String? icon;
  final String? userId; // Null for system defaults

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'userId': userId,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
      userId: map['userId'],
    );
  }
}

class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String? categoryId;
  final String userId;
  final bool isRecurring;
  final String? recurringGroupId;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryId,
    required this.userId,
    this.isRecurring = false,
    this.recurringGroupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'categoryId': categoryId,
      'userId': userId,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringGroupId': recurringGroupId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      categoryId: map['categoryId'],
      userId: map['userId'],
      isRecurring: map['isRecurring'] == 1,
      recurringGroupId: map['recurringGroupId'],
    );
  }
}
