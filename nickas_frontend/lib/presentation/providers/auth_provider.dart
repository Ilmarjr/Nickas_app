import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _userId;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;

  String get _baseUrl => AppConfig.baseUrl;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _isAuthenticated = true;
        await _storage.write(key: 'auth_token', value: _token);

        _userId = _getUserIdFromToken(_token!);

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String username,
    DateTime dateOfBirth,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
          'date_of_birth': dateOfBirth.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _isAuthenticated = false;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _token = token;
      _isAuthenticated = true;
      _userId = _getUserIdFromToken(token);
      notifyListeners();
    }
  }

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      return payloadMap['sub'];
    } catch (e) {
      print("Error parsing token: $e");
      return null;
    }
  }
}
