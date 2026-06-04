import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

// error khusus api biar pesannya ga aneh di ui
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  // biar pas di snackbar ga kebaca "Instance of..."
  @override
  String toString() => message;
}

// semua panggilan http ke backend lewat sini
class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  // simpen token login di local storage hp/browser
  static Future<void> simpanToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ambil token yang udah disimpen
  static Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // logout — hapus token & data user lokal
  static Future<void> hapusToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('siswa_id');
    await prefs.remove('siswa_nama');
    await prefs.remove('saldo_poin');
  }

  // cache nama & saldo poin biar ga fetch terus
  static Future<void> simpanDataSiswa(Map<String, dynamic> siswa) async {
    final prefs = await SharedPreferences.getInstance();
    final id = siswa['id'];
    final saldo = siswa['saldo_poin'];
    final role = siswa['role']?.toString() ?? 'siswa'; // simpan role juga
    await prefs.setInt(
      'siswa_id',
      id is int ? id : (id as num).toInt(),
    );
    await prefs.setString('siswa_nama', siswa['nama']?.toString() ?? 'Siswa');
    await prefs.setInt(
      'saldo_poin',
      saldo is int ? saldo : (saldo as num?)?.toInt() ?? 7,
    );
    await prefs.setString('role', role); // simpan role
  }

  // cek apakah user adalah admin
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'siswa';
    return role == 'admin';
  }

  // header buat request yang butuh login
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

  // ubah error ribet jadi bahasa manusia
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

  // rapihin pesan dari go/backend biar ga kaku
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

  // parse body http + cek status code
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

  // sama kayak decode body tapi buat upload multipart
  static Map<String, dynamic> _decodeStreamed(
    http.StreamedResponse response,
    String body,
  ) {
    return _decodeBody(
      http.Response(body, response.statusCode, headers: response.headers),
    );
  }

  // ambil array dari json (support key data/jasa/aksi)
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

  // ambil object dari json
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

  // wrapper request + timeout + tangkep error koneksi
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

  // daftar akun baru
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

  // login dapet token
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

  // profil user yang lagi login
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

  // riwayat transaksi jasa (poin masuk/keluar)
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

  // list jasa buat dashboard home
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

  // detail satu jasa
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

  // post jasa baru
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

  // beli/ambil jasa orang (potong poin)
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

  // tandain jasa kelar (transfer poin ke penyedia)
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

  // upload foto aksi sosial (web pake bytes, bukan file path)
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

  // list upload sosial user
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

  // ranking siswa paling banyak poin
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

  // edit nama/kelas/jurusan
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

  // hapus akun permanen
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

  // link download excel riwayat poin
  static Future<String> getExportExcelUrl() async {
    final token = await ambilToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Login dulu untuk mengunduh riwayat.');
    }
    return '$baseUrl/siswa/export?token=$token';
  }

  // cek backend hidup ga sebelum login/daftar
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

  // update saldo poin di shared preferences
  static Future<void> perbaruiSaldoLokal() async {
    final profil = await getProfil();
    final siswa = profil['siswa'];
    if (siswa is Map) {
      await simpanDataSiswa(Map<String, dynamic>.from(siswa));
    }
  }

  // abis login sync profil lengkap (saldo dll)
  static Future<void> sinkronkanProfilSetelahLogin() async {
    try {
      final profil = await getProfil();
      final siswa = profil['siswa'];
      if (siswa is Map) {
        await simpanDataSiswa(Map<String, dynamic>.from(siswa));
      }
    } catch (_) {
      // kalo gagal ya udah, login tetep jalan aja
    }
  }

  // ===== API MERCH (SISWA) =====

  // list semua merch yang tersedia
  static Future<Map<String, dynamic>> getDaftarMerch() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/merch'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'merch']),
      };
    });
  }

  // detail satu merch
  static Future<Map<String, dynamic>> getDetailMerch(int id) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/merch/$id'),
        headers: headers,
      );
      final body = _decodeBody(response);
      final detail = _mapFromBody(body, ['data', 'merch']);
      if (detail == null) {
        throw const ApiException('Detail merch tidak ditemukan.');
      }
      return {
        ...body,
        'data': detail,
      };
    });
  }

  // beli merch (tukar poin), ga perlu alamat lagi - ambil di koperasi
  static Future<Map<String, dynamic>> beliMerch({
    required int merchId,
    required int jumlah,
    String? catatan,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/merch/beli'),
        headers: headers,
        body: jsonEncode({
          'merch_id': merchId,
          'jumlah': jumlah,
          'catatan': catatan?.trim() ?? '',
        }),
      );
      return _decodeBody(response);
    });
  }

  // riwayat pesanan merch siswa
  static Future<Map<String, dynamic>> getRiwayatMerch() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/merch/riwayat'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'pesanan']),
      };
    });
  }

  // ===== API ADMIN =====

  // buat merch baru (admin)
  static Future<Map<String, dynamic>> adminBuatMerch({
    required String nama,
    required String deskripsi,
    required String fotoUrl,
    required int hargaPoin,
    required int stok,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/merch'),
        headers: headers,
        body: jsonEncode({
          'nama': nama.trim(),
          'deskripsi': deskripsi.trim(),
          'foto_url': fotoUrl.trim(),
          'harga_poin': hargaPoin,
          'stok': stok,
        }),
      );
      return _decodeBody(response);
    });
  }

  // update merch (admin)
  static Future<Map<String, dynamic>> adminUpdateMerch({
    required int id,
    required String nama,
    required String deskripsi,
    required String fotoUrl,
    required int hargaPoin,
    required int stok,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/merch/$id'),
        headers: headers,
        body: jsonEncode({
          'nama': nama.trim(),
          'deskripsi': deskripsi.trim(),
          'foto_url': fotoUrl.trim(),
          'harga_poin': hargaPoin,
          'stok': stok,
        }),
      );
      return _decodeBody(response);
    });
  }

  // hapus merch (admin)
  static Future<Map<String, dynamic>> adminHapusMerch(int id) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/merch/$id'),
        headers: headers,
      );
      return _decodeBody(response);
    });
  }

  // list semua pesanan merch (admin)
  static Future<Map<String, dynamic>> adminGetPesanan() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pesanan'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'pesanan']),
      };
    });
  }

  // update status pesanan (admin)
  static Future<Map<String, dynamic>> adminUpdateStatusPesanan({
    required int id,
    required String status,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/pesanan/$id'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _decodeBody(response);
    });
  }

  // konfirmasi ambil barang di koperasi via kode unik (admin)
  static Future<Map<String, dynamic>> adminKonfirmasiAmbil({
    required String kodeAmbil,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/pesanan/konfirmasi'),
        headers: headers,
        body: jsonEncode({'kode_ambil': kodeAmbil}),
      );
      return _decodeBody(response);
    });
  }

  // list semua aksi sosial (admin)
  static Future<Map<String, dynamic>> adminGetAksiSosial() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/sosial'),
        headers: headers,
      );
      final body = _decodeBody(response);
      return {
        ...body,
        'data': _listFromBody(body, ['data', 'aksi']),
      };
    });
  }

  // approve/reject aksi sosial (admin)
  static Future<Map<String, dynamic>> adminUpdateAksiSosial({
    required int id,
    required String status,
  }) async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/sosial/$id'),
        headers: headers,
        body: jsonEncode({
          'status': status,
        }),
      );
      return _decodeBody(response);
    });
  }

  // statistik dashboard admin
  static Future<Map<String, dynamic>> adminGetStats() async {
    return _jalankan(() async {
      final headers = await headerDenganToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: headers,
      );
      final body = _decodeBody(response);
      final stats = _mapFromBody(body, ['data', 'stats']);
      if (stats == null) {
        throw const ApiException('Statistik tidak ditemukan.');
      }
      return {
        ...body,
        'data': stats,
      };
    });
  }
}
