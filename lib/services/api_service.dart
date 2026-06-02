import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Error dengan pesan yang sudah ramah untuk ditampilkan ke user.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  static Future<void> simpanToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> hapusToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('siswa_id');
    await prefs.remove('siswa_nama');
    await prefs.remove('saldo_poin');
  }

  static Future<void> simpanDataSiswa(Map<String, dynamic> siswa) async {
    final prefs = await SharedPreferences.getInstance();
    final id = siswa['id'];
    final saldo = siswa['saldo_poin'];
    await prefs.setInt(
      'siswa_id',
      id is int ? id : (id as num).toInt(),
    );
    await prefs.setString('siswa_nama', siswa['nama']?.toString() ?? 'Siswa');
    await prefs.setInt(
      'saldo_poin',
      saldo is int ? saldo : (saldo as num?)?.toInt() ?? 7,
    );
  }

  static Future<Map<String, String>> headerDenganToken() async {
    final token = await ambilToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login habis. Silakan masuk lagi.');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Ubah error teknis jadi kalimat yang mudah dipahami.
  static String pesanUntukUser(Object error, {String? fallback}) {
    if (error is ApiException) return error.message;

    final teks = error.toString();

    if (teks.contains('ClientException') ||
        teks.contains('SocketException') ||
        teks.contains('Failed host lookup') ||
        teks.contains('Connection refused') ||
        teks.contains('NetworkError')) {
      return 'Tidak bisa menghubungi server.\n'
          '${ApiConfig.petunjukBackend}';
    }

    if (teks.contains('TimeoutException') || teks.contains('timed out')) {
      return 'Server tidak merespons. Coba lagi beberapa detik.';
    }

    if (teks.contains('FormatException')) {
      return 'Data dari server tidak valid. Pastikan backend versi terbaru sudah dijalankan.';
    }

    return fallback ?? 'Terjadi kesalahan. Coba lagi.';
  }

  static String _rapihkanPesanServer(String? pesan, int statusCode) {
    if (pesan != null && pesan.trim().isNotEmpty) {
      final p = pesan.trim();
      if (p.contains("Field validation") || p.contains('binding')) {
        if (p.toLowerCase().contains('email')) {
          return 'Email wajib diisi dengan format yang benar.';
        }
        if (p.toLowerCase().contains('password')) {
          return 'Password wajib diisi.';
        }
        if (p.toLowerCase().contains('nama')) {
          return 'Nama wajib diisi.';
        }
        if (p.toLowerCase().contains('kelas')) {
          return 'Kelas wajib diisi.';
        }
        if (p.toLowerCase().contains('jurusan')) {
          return 'Jurusan wajib diisi.';
        }
        if (p.toLowerCase().contains('judul')) {
          return 'Judul jasa wajib diisi.';
        }
        if (p.toLowerCase().contains('kategori')) {
          return 'Kategori wajib dipilih.';
        }
        if (p.toLowerCase().contains('deskripsi')) {
          return 'Deskripsi wajib diisi.';
        }
        if (p.toLowerCase().contains('harga_poin') || p.contains('HargaPoin')) {
          return 'Harga poin wajib dipilih.';
        }
        return 'Lengkapi semua data yang wajib diisi.';
      }
      return p;
    }

    switch (statusCode) {
      case 400:
        return 'Data yang dikirim tidak lengkap atau tidak valid.';
      case 401:
        return 'Email/password salah, atau sesi login sudah habis. Masuk ulang.';
      case 403:
        return 'Kamu tidak punya izin untuk aksi ini.';
      case 404:
        return 'Data tidak ditemukan di server.';
      case 500:
        return 'Server mengalami gangguan. Coba lagi nanti.';
      default:
        return 'Permintaan gagal (kode $statusCode).';
    }
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    final raw = response.body.trim();

    if (raw.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {};
      }
      throw ApiException(
        _rapihkanPesanServer(null, response.statusCode),
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const ApiException(
        'Server mengirim respons yang tidak bisa dibaca. '
        'Periksa apakah backend sudah berjalan.',
      );
    }

    Map<String, dynamic> map;
    if (decoded is Map<String, dynamic>) {
      map = decoded;
    } else if (decoded is Map) {
      map = Map<String, dynamic>.from(decoded);
    } else {
      throw const ApiException('Format data dari server tidak dikenali.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final pesan = map['pesan']?.toString() ??
          map['message']?.toString() ??
          map['error']?.toString();
      throw ApiException(_rapihkanPesanServer(pesan, response.statusCode));
    }

    return map;
  }

  static Map<String, dynamic> _decodeStreamed(
    http.StreamedResponse response,
    String body,
  ) {
    return _decodeBody(
      http.Response(body, response.statusCode, headers: response.headers),
    );
  }

  static List<dynamic> _listFromBody(
    Map<String, dynamic> body,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) return value;
    }
    return [];
  }

  static Map<String, dynamic>? _mapFromBody(
    Map<String, dynamic> body,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = body[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi().timeout(_timeout);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server terlalu lama. Periksa backend lalu coba lagi.',
      );
    } on http.ClientException {
      throw ApiException(
        'Tidak bisa terhubung ke $baseUrl.\n${ApiConfig.petunjukBackend}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(pesanUntukUser(e));
    }
  }

  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String kelas,
    String jurusan = 'RPL',
  }) async {
    return _jalankan(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama': nama.trim(),
          'email': email.trim(),
          'password': password,
          'kelas': kelas.trim(),
          'jurusan': jurusan.trim(),
        }),
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _jalankan(() async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> getProfil() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/siswa/profil'),
        headers: headers,
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> getRiwayat() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/siswa/riwayat'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'riwayat': _listFromBody(body, ['riwayat', 'data']),
      };
    });
  }

  static Future<Map<String, dynamic>> getDaftarJasa() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/jasa'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'jasa']),
      };
    });
  }

  static Future<Map<String, dynamic>> getDetailJasa(int id) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/jasa/$id'),
        headers: headers,
      );
      final body = _decodeBody(response);
      final detail = _mapFromBody(body, ['data', 'jasa']);
      if (detail == null) {
        throw const ApiException('Detail jasa tidak ditemukan.');
      }
      return {
        ...body,
        'data': detail,
      };
    });
  }

  static Future<Map<String, dynamic>> buatIklan({
    required String judul,
    required String kategori,
    required String deskripsi,
    required int hargaPoin,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/jasa'),
        headers: headers,
        body: jsonEncode({
          'judul': judul.trim(),
          'kategori': kategori.trim(),
          'deskripsi': deskripsi.trim(),
          'harga_poin': hargaPoin,
        }),
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> ambilJasa(int jasaId) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/jasa/$jasaId/ambil'),
        headers: headers,
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> selesaikanJasa(int transaksiId) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/jasa/$transaksiId/selesai'),
        headers: headers,
      );
      return _decodeBody(response);
    });
  }

  /// Upload bukti aksi sosial — mendukung Flutter Web (Chrome) dan mobile.
  static Future<Map<String, dynamic>> uploadAksiSosial({
    required String deskripsi,
    required List<int> fotoBytes,
    required String namaFile,
  }) async {
    return _jalankan(() async {
      final token = await ambilToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('Sesi login habis. Silakan masuk lagi.');
      }

      if (fotoBytes.isEmpty) {
        throw const ApiException('File foto kosong. Pilih gambar lain.');
      }

      final nama = namaFile.trim().isEmpty ? 'foto.jpg' : namaFile;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sosial/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['deskripsi'] = deskripsi.trim();
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: nama,
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final body = await streamed.stream.bytesToString();
      return _decodeStreamed(streamed, body);
    });
  }

  static Future<Map<String, dynamic>> getRiwayatSosial() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/sosial/riwayat'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'aksi']),
      };
    });
  }

  static Future<Map<String, dynamic>> getLeaderboard() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'leaderboard']),
      };
    });
  }

  static Future<Map<String, dynamic>> updateProfil({
    required String nama,
    required String kelas,
    required String jurusan,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.put(
        Uri.parse('$baseUrl/siswa'),
        headers: headers,
        body: jsonEncode({
          'nama': nama.trim(),
          'kelas': kelas.trim(),
          'jurusan': jurusan.trim(),
        }),
      );
      return _decodeBody(response);
    });
  }

  static Future<Map<String, dynamic>> hapusAkun() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/siswa'),
        headers: headers,
      );
      return _decodeBody(response);
    });
  }

  static Future<String> getExportExcelUrl() async {
    final token = await ambilToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Login dulu untuk mengunduh riwayat.');
    }
    return '$baseUrl/siswa/export?token=$token';
  }

  /// Cek apakah backend + database siap (tanpa login).
  static Future<bool> cekKoneksiBackend() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      return body is Map && body['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Muat ulang saldo poin ke penyimpanan lokal.
  static Future<void> perbaruiSaldoLokal() async {
    final profil = await getProfil();
    final siswa = profil['siswa'];
    if (siswa is Map) {
      await simpanDataSiswa(Map<String, dynamic>.from(siswa));
    }
  }

  /// Setelah login, lengkapi data siswa (termasuk saldo) dari profil.
  static Future<void> sinkronkanProfilSetelahLogin() async {
    try {
      final profil = await getProfil();
      final siswa = profil['siswa'];
      if (siswa is Map) {
        await simpanDataSiswa(Map<String, dynamic>.from(siswa));
      }
    } catch (_) {
      // Profil opsional; login tetap boleh lanjut
    }
  }
}
