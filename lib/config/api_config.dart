import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi URL API — disesuaikan untuk Flutter Web (Chrome) dan mobile.
class ApiConfig {
  static const int port = 3000;

  /// Base URL API (tanpa slash di akhir path endpoint).
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:$port/api';
      }
      return '${Uri.base.scheme}://$host:$port/api';
    }
    // Emulator Android: ganti ke http://10.0.2.2:3000/api
    return 'http://localhost:$port/api';
  }

  static String get petunjukBackend {
    if (kIsWeb) {
      return 'Buka terminal, masuk folder backend, lalu jalankan: go run .\n'
          'Setelah muncul "Server jalan di port 3000", refresh halaman Chrome (F5).';
    }
    return 'Pastikan server backend aktif di port $port.';
  }
}
