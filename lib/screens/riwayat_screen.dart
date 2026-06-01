import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  // bikin state-nya
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List _riwayat = [];
  bool _loading = true;

  @override
  // pas widget pertama kali jalan, langsung load data riwayatnya
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  // ngambil list histori transaksi jasa
  Future<void> _loadRiwayat() async {
    try {
      final res = await ApiService.getRiwayat();
      if (res['riwayat'] != null && mounted) {
        setState(() => _riwayat = res['riwayat']);
      }
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }
  
  // fungsi buat nyelesain jasa kalo kita penyedianya
  Future<void> _selesaikan(int id) async {
    try {
      final res = await ApiService.selesaikanJasa(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil')));
        _loadRiwayat();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyelesaikan jasa')));
    }
  }

  @override
  // ini bagian yang ngerender tampilan layar riwayat
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _riwayat.length,
            itemBuilder: (ctx, i) {
              final r = _riwayat[i];
              // cek arah transaksinya, keluar atau masuk
              final isKeluar = r['arah_poin'] == 'keluar';
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(isKeluar ? Icons.arrow_downward : Icons.arrow_upward, color: isKeluar ? Colors.red : Colors.green),
                  title: Text(r['nama_jasa'] ?? ''),
                  subtitle: Text('Status: ${r['status']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isKeluar ? '-' : '+'}${r['jumlah_poin']} Poin', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: isKeluar ? Colors.red : Colors.green)
                      ),
                      if (r['status'] == 'berjalan' && !isKeluar)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.blue),
                          onPressed: () => _selesaikan(r['id']),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
