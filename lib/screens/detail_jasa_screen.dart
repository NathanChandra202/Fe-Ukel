import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DetailJasaScreen extends StatefulWidget {
  final int jasaId;
  const DetailJasaScreen({super.key, required this.jasaId});

  @override
  // bikin state buat layar detail ini
  State<DetailJasaScreen> createState() => _DetailJasaScreenState();
}

class _DetailJasaScreenState extends State<DetailJasaScreen> {
  Map<String, dynamic>? _jasa;
  bool _loading = true;

  @override
  // pas pertama dibuka, langsung narik data detail jasanya
  void initState() {
    super.initState();
    _loadDetail();
  }

  // narik detail satu jasa
  Future<void> _loadDetail() async {
    try {
      final res = await ApiService.getDetailJasa(widget.jasaId);
      if (res['data'] != null && mounted) {
        setState(() => _jasa = res['data']);
      }
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  // fungsi buat ngambil kerjaan
  Future<void> _ambilTugas() async {
    try {
      final res = await ApiService.ambilJasa(widget.jasaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil ngambil jasa')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil jasa')));
    }
  }

  @override
  // ngerender tampilan halaman detail jasa
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_jasa == null) return const Scaffold(body: Center(child: Text('Jasa tidak ditemukan')));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jasa')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_jasa!['judul'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Dibuat oleh: ${_jasa!['nama_penyedia']}'),
            const SizedBox(height: 10),
            Text('Kategori: ${_jasa!['kategori']}'),
            const SizedBox(height: 20),
            const Text('Deskripsi:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_jasa!['deskripsi'] ?? ''),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_jasa!['harga_poin']} Poin', style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: _ambilTugas, child: const Text('Ambil Tugas')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
