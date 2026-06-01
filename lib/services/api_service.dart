import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // simpan token ke hp
  static Future<void> simpanToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // ambil token dari hp
  static Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // hapus token sama data user di hp kalo logout
  static Future<void> hapusToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('siswa_id');
    await prefs.remove('siswa_nama');
  }

  // nyimpen data siswa sementara
  static Future<void> simpanDataSiswa(Map<String, dynamic> siswa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('siswa_id', siswa['id']);
    await prefs.setString('siswa_nama', siswa['nama']);
    await prefs.setInt('saldo_poin', siswa['saldo_poin'] ?? 7);
  }

  // ngasih header auth buat request
  static Future<Map<String, String>> headerDenganToken() async {
    final token = await ambilToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // fungsi buat daftar
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String kelas,
    String jurusan = 'RPL',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'kelas': kelas,
        'jurusan': jurusan,
      }),
    );
    return jsonDecode(response.body);
  }

  // fungsi buat login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // fungsi ngambil profil
  static Future<Map<String, dynamic>> getProfil() async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/siswa/profil'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ngambil riwayat transaksi
  static Future<Map<String, dynamic>> getRiwayat() async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/siswa/riwayat'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ngambil daftar jasa yang ada
  static Future<Map<String, dynamic>> getDaftarJasa() async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/jasa'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ngambil detail jasa per item
  static Future<Map<String, dynamic>> getDetailJasa(int id) async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/jasa/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // buat nawarin jasa baru
  static Future<Map<String, dynamic>> buatIklan({
    required String judul,
    required String kategori,
    required String deskripsi,
    required int hargaPoin,
  }) async {
    final headers = await headerDenganToken();
    final response = await http.post(
      Uri.parse('$baseUrl/jasa'),
      headers: headers,
      body: jsonEncode({
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'harga_poin': hargaPoin,
      }),
    );
    return jsonDecode(response.body);
  }

  // ngambil jasa orang lain
  static Future<Map<String, dynamic>> ambilJasa(int jasaId) async {
    final headers = await headerDenganToken();
    final response = await http.post(
      Uri.parse('$baseUrl/jasa/$jasaId/ambil'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // nandain jasa udah kelar
  static Future<Map<String, dynamic>> selesaikanJasa(int transaksiId) async {
    final headers = await headerDenganToken();
    final response = await http.post(
      Uri.parse('$baseUrl/jasa/$transaksiId/selesai'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ngeupload foto aksi sosial
  static Future<Map<String, dynamic>> uploadAksiSosial({
    required String deskripsi,
    required File foto,
  }) async {
    final token = await ambilToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/sosial/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['deskripsi'] = deskripsi;
    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body);
  }

  // ngambil history aksi sosial
  static Future<Map<String, dynamic>> getRiwayatSosial() async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/sosial/riwayat'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ngambil data leaderboard
  static Future<Map<String, dynamic>> getLeaderboard() async {
    final headers = await headerDenganToken();
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // update data profil
  static Future<Map<String, dynamic>> updateProfil({
    required String nama,
    required String kelas,
    required String jurusan,
  }) async {
    final headers = await headerDenganToken();
    final response = await http.put(
      Uri.parse('$baseUrl/siswa'),
      headers: headers,
      body: jsonEncode({
        'nama': nama,
        'kelas': kelas,
        'jurusan': jurusan,
      }),
    );
    return jsonDecode(response.body);
  }

  // hapus akun permanen
  static Future<Map<String, dynamic>> hapusAkun() async {
    final headers = await headerDenganToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/siswa'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // buat link export excel pake token
  static Future<String> getExportExcelUrl() async {
    final token = await ambilToken();
    return '$baseUrl/siswa/export?token=$token';
  }
}
