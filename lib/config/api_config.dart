import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int port = 3000;

  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:$port/api';
      }
      return '${Uri.base.scheme}://$host:$port/api';
    }

    // IP laptop lu
    return 'http://15.15.6.45:$port/api';
  }

  static String get petunjukBackend {
    return 'Pastikan server backend aktif di port $port.';
  }
}
