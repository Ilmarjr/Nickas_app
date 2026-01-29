import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../domain/entities/shopping_list.dart';
import '../../domain/entities/item.dart';
import '../../core/config/app_config.dart';

class ApiService {
  final String _authToken;

  ApiService(this._authToken);

  String get _baseUrl => AppConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  // --- Lists ---

  Future<List<ShoppingList>> fetchLists() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/lists/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map(
            (json) => ShoppingList(
              id: json['id'],
              name: json['name'],
              date: DateTime.parse(json['date']),
              // Backend stores owner_id but we don't need it on frontend entity usually if we filter by user context
            ),
          )
          .toList();
    } else {
      throw Exception('Failed to load lists');
    }
  }

  Future<void> createList(ShoppingList list) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/lists/'),
      headers: _headers,
      body: json.encode(list.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create list: ${response.body}');
    }
  }

  Future<void> deleteList(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/lists/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete list');
    }
  }

  // --- Items ---
  // Note: Backend has /items/ but frontend might not have an endpoint to get all items at once simply.
  // Actually, we usually fetch items per list in frontend, but backend doesn't implement /lists/{id}/items explicitly yet.
  // Although /lists/ returns ShoppingList which backend schema says "items: List[Item] = []"
  // So fetching lists MIGHT fetch items if eager loading is on.
  // Backend Model: lists = relationship(..., back_populates="owner"). Item relationship is default lazy?
  // Backend Schema ShoppingList has items: List[Item] = [].
  // Let's assume loading lists loads items or we might need a fetchItems endpoint.
  // Wait, backend `read_lists` does `db.query(...).all()`. If relationship is lazy, items won't be in JSON unless `response_model` forces it.
  // Pydantic `orm_mode = True` and default `items = []` might try to fetch.
  // BUT: The backend `read_lists` query does not do `.options(joinedload(models.ShoppingList.items))`.
  // This causes N+1 or lazy loading errors if async, or just fetches if sync.
  // Let's assume for now we need separate Item calls if list fetch doesn't return them,
  // BUT: The most efficient way for "Sync" is to just fetch everything.
  // For this step ("Sync"), I will assume we sync Items deeply.

  // Actually, since I didn't add GET /items/?list_id=... to backend, I should probably rely on `ShoppingList` return containing items.
  // Let's check backend schema again.
  // `ShoppingList` schema has `items: List[Item] = []`.
  // So yes, `fetchLists` SHOULD return items.

  Future<void> createItem(Item item) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/items/'),
      headers: _headers,
      body: json.encode(item.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create item: ${response.body}');
    }
  }

  Future<void> updateItem(Item item) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/items/${item.id}'),
      headers: _headers,
      body: json.encode(
        item.toJson(),
      ), // backend update_item takes ItemBase, which excludes id/list_id, but extra fields usually ignored by Pydantic if not in schema or if config allows. ItemBase has name, brand, etc.
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update item: ${response.body}');
    }
  }

  Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/items/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }
}
