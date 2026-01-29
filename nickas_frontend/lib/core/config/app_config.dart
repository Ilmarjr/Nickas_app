import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool get isDev =>
      (dotenv.env['ENVIRONMENT']?.toLowerCase() ?? 'dev') == 'dev';

  static String get baseUrl {
    if (isDev) {
      // Localhost handling for different platforms
      if (kIsWeb) {
        return 'http://127.0.0.1:8000';
      }

      // Android Emulator uses 10.0.2.2 to access host machine
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }

      // Windows / iOS Simulator / macOS / Linux
      return 'http://127.0.0.1:8000';
    }

    // Production URL loaded from .env
    return dotenv.env['API_BASE_URL'] ?? 'https://nickas-backend.onrender.com';
  }
}
