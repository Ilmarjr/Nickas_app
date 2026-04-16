import 'package:flutter/material.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/item.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/services/api_service.dart';

class ShoppingListProvider with ChangeNotifier {
  List<ShoppingList> _lists = [];
  bool _isLoading = false;
  String _currentUserId = '';
  ApiService? _apiService;

  List<ShoppingList> get lists => _lists;
  bool get isLoading => _isLoading;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  void update(String? userId, String? token) {
    if (userId != null && userId != _currentUserId) {
      _currentUserId = userId;
      if (token != null) {
        _apiService = ApiService(token);
      } else {
        _apiService = null;
      }
      loadLists(forceRefresh: true);
    } else if (userId == null) {
      _currentUserId = '';
      _apiService = null;
      _lists = [];
      notifyListeners();
    }
  }

  Future<void> loadLists({bool forceRefresh = false}) async {
    if (_currentUserId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    // 1. Load local first for speed
    await _loadFromLocal();

    // Libera a tela com os dados locais imediatamente para não travar
    _isLoading = false;
    notifyListeners();

    // 2. If connected and refresh requested, fetch from API and sync
    if (forceRefresh && _apiService != null) {
      _syncInBackground();
    }
  }

  Future<void> _syncInBackground() async {
    try {
      final remoteLists = await _apiService!.fetchLists();
      // Simple Sync: Server overwrites local for this user
      // Ideally we would merge using 'lastSynced'
      await _syncRemoteToLocal(remoteLists);
      await _loadFromLocal(); // Reload updated data
      notifyListeners();
    } catch (e) {
      print("Sync error: $e");
      // Keep showing local data if sync fails
    }
  }

  Future<void> _loadFromLocal() async {
    final data = await _dbHelper.getLists(_currentUserId);
    _lists = data.map((e) => _mapToList(e)).toList();
  }

  Future<void> _syncRemoteToLocal(List<ShoppingList> remoteLists) async {
    // Merge Strategy: Upsert remote data into local. Do NOT delete local data.

    for (var list in remoteLists) {
      await _dbHelper.insertList({
        'id': list.id,
        'userId': _currentUserId,
        'name': list.name,
        'date': list.date.toIso8601String(),
        'isDeleted': 0,
        'lastSynced': DateTime.now().toIso8601String(),
      });
    }

    await _uploadUnsyncedData(remoteLists);
  }

  Future<void> _uploadUnsyncedData(List<ShoppingList> remoteLists) async {
    final remoteIds = remoteLists.map((l) => l.id).toSet();
    // Use current _lists as source of local truth
    for (var localList in _lists) {
      if (!remoteIds.contains(localList.id)) {
        try {
          if (_apiService != null) {
            print("Uploading local list to cloud: ${localList.name}");
            await _apiService!.createList(localList);
            // Mark as synced locally
            await _dbHelper.insertList({
              'id': localList.id,
              'userId': _currentUserId,
              'name': localList.name,
              'date': localList.date.toIso8601String(),
              'isDeleted': 0,
              'lastSynced': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print("Failed to upload list ${localList.name}: $e");
        }
      }
    }
  }

  ShoppingList _mapToList(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      isDeleted: map['isDeleted'] == 1,
      lastSynced: map['lastSynced'] != null
          ? DateTime.parse(map['lastSynced'])
          : null,
      summaryTotal: map['totalValue'] != null
          ? (map['totalValue'] as num).toDouble()
          : 0.0,
    );
  }

  Future<void> addList(String name) async {
    if (_currentUserId.isEmpty) return;

    final newList = ShoppingList(name: name, date: DateTime.now());

    if (_apiService != null) {
      try {
        await _apiService!.createList(newList);
      } catch (e) {
        print("API create list failed: $e");
      }
    }

    await _dbHelper.insertList({
      'id': newList.id,
      'userId': _currentUserId,
      'name': newList.name,
      'date': newList.date.toIso8601String(),
      'isDeleted': 0,
      'lastSynced': _apiService != null
          ? DateTime.now().toIso8601String()
          : null,
    });

    _lists.add(newList);
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    if (_apiService != null) {
      try {
        await _apiService!.deleteList(id);
      } catch (e) {
        print("API delete list failed: $e");
      }
    }

    await _dbHelper.deleteList(id);
    _lists.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  // --- Item Management ---

  List<Item> _currentItems = [];
  List<Item> get currentItems => _currentItems;

  Future<void> loadItems(String listId) async {
    _isLoading = true;
    notifyListeners();

    final data = await _dbHelper.getItems(listId);
    _currentItems = data.map((e) => _mapToItem(e)).toList();
    _sortItems();

    _isLoading = false;
    notifyListeners();
  }

  Item _mapToItem(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      listId: map['listId'],
      name: map['name'],
      brand: map['brand'] ?? '',
      quantity: map['quantity'],
      price: map['price'],
      isChecked: map['isChecked'] == 1,
      isDeleted: map['isDeleted'] == 1,
    );
  }

  Future<void> addItem(Item item) async {
    if (_apiService != null) {
      try {
        await _apiService!.createItem(item);
      } catch (e) {
        print("API create item failed: $e");
      }
    }

    await _dbHelper.insertItem(item.toMap());
    _currentItems.add(item);
    _sortItems();
    notifyListeners();
  }

  Future<void> updateItem(Item item) async {
    if (_apiService != null) {
      try {
        await _apiService!.updateItem(item);
      } catch (e) {
        print("API update item failed: $e");
      }
    }

    await _dbHelper.updateItem(item.toMap());
    int index = _currentItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _currentItems[index] = item;
      _sortItems();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    if (_apiService != null) {
      try {
        await _apiService!.deleteItem(id);
      } catch (e) {
        print("API delete item failed: $e");
      }
    }

    await _dbHelper.deleteItem(id);
    _currentItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void _sortItems() {
    _currentItems.sort((a, b) {
      if (a.isChecked && !b.isChecked) return 1;
      if (!a.isChecked && b.isChecked) return -1;
      return a.name.compareTo(b.name);
    });
  }
}
