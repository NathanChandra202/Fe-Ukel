import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detail_jasa_screen.dart';

class JasaScreen extends StatefulWidget {
  const JasaScreen({super.key});

  @override
  State<JasaScreen> createState() => _JasaScreenState();
}

class _JasaScreenState extends State<JasaScreen> {
  List _jasaList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ambilJasa();
  }

  // narik semua data jasa yang ada
  Future<void> _ambilJasa() async {
    try {
      final res = await ApiService.getDaftarJasa();
      if (res['data'] != null && mounted) {
        setState(() => _jasaList = res['data']);
      }
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Jasa')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/buat_iklan');
          _ambilJasa();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _jasaList.length,
            itemBuilder: (ctx, i) {
              final j = _jasaList[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(j['judul'] ?? ''),
                  subtitle: Text(j['nama_penyedia'] ?? ''),
                  trailing: Text('${j['harga_poin']} Poin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailJasaScreen(jasaId: j['id'])));
                    _ambilJasa();
                  },
                ),
              );
            },
          ),
    );
  }
}
