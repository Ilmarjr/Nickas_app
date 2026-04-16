import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/finance_models.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _userId;

  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  double _marketExpense = 0.0;

  // Date Navigation State
  DateTime _selectedDate = DateTime.now();

  List<CategoryModel> get categories => _categories;
  DateTime get selectedDate => _selectedDate;

  // Filtered Getters
  List<TransactionModel> get transactions {
    // Return only transactions for the selected month/year
    return _transactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
    }).toList();
  }

  // Provide raw list if needed, but 'transactions' is primarily used for UI.
  // Actually, let's keep 'transactions' filtered.

  double get marketExpense => _marketExpense;

  void updateContext(String? userId) {
    if (userId != null && userId != _userId) {
      _userId = userId;
      loadData();
    }
  }

  void nextMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    loadData(); // Reload market expense for new month
  }

  void previousMonth() {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    loadData();
  }

  Future<void> loadData() async {
    if (_userId == null) return;

    // 1. Load Categories
    final catMaps = await _dbHelper.getCategories(_userId!);
    _categories = catMaps.map((e) => CategoryModel.fromMap(e)).toList();

    if (_categories.isEmpty) {
      await _seedDefaultCategories();
    }

    // 2. Load Transactions (Load ALL, filter in memory is okay for local MVP)
    // Optimization: Could filter in SQL. For now, memory is fine.
    final transMaps = await _dbHelper.getTransactions(_userId!);
    // Sort by date desc
    _transactions = transMaps.map((e) => TransactionModel.fromMap(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // 3. Calculate Market Expense (Filter by Selected Month)
    await _calculateMarketExpense();

    notifyListeners();
  }

  /// Atualiza APENAS o total do mercado sem consultar o banco —
  /// recebe o valor já calculado em memória pelo ShoppingListProvider.
  void setMarketExpense(double total) {
    _marketExpense = total;
    notifyListeners();
  }

  /// Fallback: recalcula via banco (usado no loadData e navegação de mês).
  Future<void> _calculateMarketExpense() async {
    final lists = await _dbHelper.getLists(_userId!);

    // Filter lists that fall within the selected month
    final monthlyLists = lists.where((l) {
      // 'date' in map is String ISO or int? DatabaseHelper uses TEXT ISO8601 usually or int timestamp.
      // Let's check DatabaseHelper. It usually returns Maps.
      // Assuming 'date' column exists.
      // Checking getLists: it does queries.
      // Need to be careful with type.
      // In ShoppingListProvider it parses DateTime.parse(maps[i]['date'])
      final dateStr = l['date'] as String;
      final date = DateTime.parse(dateStr);
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month;
    });

    _marketExpense = monthlyLists.fold(
      0.0,
      (sum, item) => sum + (item['totalValue'] as num).toDouble(),
    );
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      {'name': 'Investimentos', 'color': '0xFF4CAF50', 'icon': 'trending_up'}, // Verde
      {'name': 'Aluguel', 'color': '0xFFFF5733', 'icon': 'home'},
      {'name': 'Transporte', 'color': '0xFF33C1FF', 'icon': 'directions_bus'},
      {'name': 'Saúde', 'color': '0xFFE91E63', 'icon': 'fitness_center'},
      {'name': 'Lazer', 'color': '0xFFF3FF33', 'icon': 'movie'},
      {'name': 'Alimentação', 'color': '0xFFFF9800', 'icon': 'restaurant'},
      {'name': 'Outros', 'color': '0xFF9E9E9E', 'icon': 'category'},
    ];

    for (var def in defaults) {
      final newCat = CategoryModel(
        id: const Uuid().v4(),
        name: def['name']!,
        color: def['color']!,
        icon: def['icon'], // Added
        userId: _userId,
      );
      await _dbHelper.insertCategory(newCat.toMap());
    }
    final catMaps = await _dbHelper.getCategories(_userId!);
    _categories = catMaps.map((e) => CategoryModel.fromMap(e)).toList();
  }

  // REFACTORED addTransaction above to support this flow cleanly:

  Future<void> addTransaction({
    required String description,
    required double amount,
    required DateTime date,
    required String type,
    String? categoryId,
    bool isRecurring = false,
  }) async {
    final String? groupId = isRecurring ? const Uuid().v4() : null;

    // 1. Add Original Transaction
    final newTrans = TransactionModel(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      date: date,
      type: type,
      categoryId: categoryId,
      userId: _userId!,
      isRecurring: isRecurring,
      recurringGroupId: groupId,
    );

    await _dbHelper.insertTransaction(newTrans.toMap());

    // 2. If Recurring, generate for next 11 months
    if (isRecurring) {
      await _generateRecurringClones(
        description: description,
        amount: amount,
        date: date,
        type: type,
        categoryId: categoryId,
        userId: _userId!,
        groupId: groupId!,
      );
    } else {
      print('[DEBUG] Transaction is NOT recurring.');
    }

    await loadData();
  }

  Future<void> _generateRecurringClones({
    required String description,
    required double amount,
    required DateTime date,
    required String type,
    String? categoryId,
    required String userId,
    required String groupId,
  }) async {
    for (int i = 1; i <= 11; i++) {
      // Handle month overflow correctly
      // Start date components
      int year = date.year;
      int month = date.month + i;
      int day = date.day;

      // Calculate correct year/month
      while (month > 12) {
        month -= 12;
        year++;
      }

      // Clamp day to max days in that month
      int maxDays = DateTime(
        year,
        month + 1,
        0,
      ).day; // day 0 of next month = last day of current
      if (day > maxDays) {
        day = maxDays;
      }

      final nextDate = DateTime(year, month, day);
      print('[DEBUG] Generating Recurring $i: $nextDate');

      final recurringTrans = TransactionModel(
        id: const Uuid().v4(),
        description: description,
        amount: amount,
        date: nextDate,
        type: type,
        categoryId: categoryId,
        userId: userId,
        isRecurring: true,
        recurringGroupId: groupId,
      );
      try {
        await _dbHelper.insertTransaction(recurringTrans.toMap());
        print(
          '[DEBUG] Inserted clone for month $i with type $type and cat $categoryId',
        );
      } catch (e) {
        print('[ERROR] Failed to insert clone for month $i: $e');
      }
    }
  }

  Future<void> updateTransaction(TransactionModel t) async {
    // Check old state
    bool wasRecurring = false;
    String? oldGroupId;

    try {
      final oldList = await _dbHelper.getTransactions(_userId!);
      final oldMap = oldList.firstWhere((m) => m['id'] == t.id);
      wasRecurring = (oldMap['isRecurring'] == 1);
      oldGroupId = oldMap['recurringGroupId'];
    } catch (e) {
      // not found
    }

    // Logic:
    // 1. Turned OFF (True -> False):
    //    - Delete all future transactions with same recurringGroupId.
    //    - Update this one to non-recurring, remove ID.

    // 2. Turned ON (False -> True):
    //    - Generate new ID.
    //    - Update this one with new ID.
    //    - Generate clones.

    // 3. Stayed ON (True -> True):
    //    - Update logic usually (e.g. amount change).
    //    - Ideally should update clones too, but user didn't ask explicitly yet.
    //    - Current request is specifically about turning OFF deleting futures.

    TransactionModel finalTransaction = t;

    if (wasRecurring && !t.isRecurring) {
      // 1. Turning OFF
      print('[DEBUG] Turning OFF recurring. Deleting future series.');
      if (oldGroupId != null) {
        // We need to delete where groupId == oldGroupId AND date > t.date
        // Since we don't have a complex delete query exposed in helper,
        // we can fetch all, filter IDs, and delete loop.
        final allCheck = await _dbHelper.getTransactions(_userId!);
        final toDelete = allCheck.where((m) {
          final mDate = DateTime.parse(m['date']);
          return m['recurringGroupId'] == oldGroupId && mDate.isAfter(t.date);
        }).toList();

        for (var del in toDelete) {
          await _dbHelper.deleteTransaction(del['id']);
          print('[DEBUG] Deleted future occurrence: ${del['description']}');
        }
      }
      // Ensure the updated transaction clears the group ID
      finalTransaction = TransactionModel(
        id: t.id,
        description: t.description,
        amount: t.amount,
        date: t.date,
        type: t.type,
        categoryId: t.categoryId,
        userId: t.userId,
        isRecurring: false,
        recurringGroupId: null, // Clear it
      );
    } else if (!wasRecurring && t.isRecurring) {
      // 2. Turning ON
      print('[DEBUG] Turning ON recurring. Generating series.');
      final newGroupId = const Uuid().v4();

      // Update this transaction with new ID
      finalTransaction = TransactionModel(
        id: t.id,
        description: t.description,
        amount: t.amount,
        date: t.date,
        type: t.type,
        categoryId: t.categoryId,
        userId: t.userId,
        isRecurring: true,
        recurringGroupId: newGroupId,
      );

      await _generateRecurringClones(
        description: finalTransaction.description,
        amount: finalTransaction.amount,
        date: finalTransaction.date,
        type: finalTransaction.type,
        categoryId: finalTransaction.categoryId,
        userId: finalTransaction.userId,
        groupId: newGroupId,
      );
    }

    await _dbHelper.updateTransaction(finalTransaction.toMap());

    // Note: If True->True, we just update this one.
    // If we wanted to update the series (e.g. amount change propagates),
    // that would be extra logic here. Keeping it scoped to request.

    await loadData();
  }

  Future<void> deleteTransaction(String id) async {
    await _dbHelper.deleteTransaction(id);
    await loadData();
  }

  Future<void> addCategory(String name, String colorHex) async {
    final newCat = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      color: colorHex,
      userId: _userId,
    );
    await _dbHelper.insertCategory(newCat.toMap());
    await loadData();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _dbHelper.updateCategory(category.toMap());
    await loadData();
  }
}
